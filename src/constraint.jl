export moments

abstract type PolynomialSet end

function JuMP.in_set_string(print_mode, set::PolynomialSet)
    return string(JuMP._math_symbol(print_mode, :in), ' ', set)
end

struct ZeroPoly <: PolynomialSet end
struct NonNegPoly <: PolynomialSet end
struct PosDefPolyMatrix <: PolynomialSet end

function JuMP.function_string(::Type{JuMP.REPLMode},
                              p::MultivariatePolynomials.APL)
    return sprint(show, MIME"text/plain"(), p)
end
function JuMP.function_string(::Type{JuMP.IJuliaMode},
                              p::MultivariatePolynomials.APL)
    # `show` prints `$$` around what `_show` prints.
    return sprint(MultivariatePolynomials._show, MIME"text/latex"(), p)
end

### Shapes for polynomial/moments primal-dual pair ###

# Inspired from `JuMP.dual_shape` docstring example
struct PolynomialShape{MT <: AbstractMonomial,
                       MVT <: AbstractVector{MT}} <: JuMP.AbstractShape
    monomials::MVT
end
function JuMP.reshape_vector(x::Vector, shape::PolynomialShape)
    return polynomial(x, shape.monomials)
end
struct MomentsShape{MT <: AbstractMonomial,
                    MVT <: AbstractVector{MT}} <: JuMP.AbstractShape
    monomials::MVT
end
function JuMP.reshape_vector(x::Vector, shape::MomentsShape)
    return measure(x, shape.monomials)
end
JuMP.dual_shape(shape::PolynomialShape) = MomentsShape(shape.monomials)
JuMP.dual_shape(shape::MomentsShape) = PolynomialShape(shape.monomials)

JuMP.reshape_set(::ZeroPolynomialSet, ::PolynomialShape) = ZeroPoly()
function JuMP.moi_set(::ZeroPoly, monos::AbstractVector{<:AbstractMonomial};
                      domain::AbstractSemialgebraicSet=FullSpace(),
                      basis=MonomialBasis)
    return ZeroPolynomialSet(domain, basis, monos)
end

"""
    moments(cref::JuMP.ConstraintRef)

Return the [`MomentsAttribute`](@ref) of `cref`.
"""
function MultivariateMoments.moments(cref::JuMP.ConstraintRef)
    return MOI.get(cref.model, MomentsAttribute(), cref)
end

"""
    bridges(F::Type{<:MOI.AbstractFunction}, S::Type{<:MOI.AbstractSet})

Return a list of bridges that may be needed to bridge `F`-in-`S` constraints but
not the bridges that may be needed by constraints added by the bridges.
"""
bridges(::Type{<:MOI.AbstractFunction}, ::Type{<:MOI.AbstractSet}) = []

function bridges(::Type{<:MOI.AbstractVectorFunction},
                 ::Type{<:ZeroPolynomialSet{FullSpace}})
    return [ZeroPolynomialBridge]
end

function bridges(::Type{<:MOI.AbstractVectorFunction},
                 ::Type{<:ZeroPolynomialSet{<:AbstractAlgebraicSet}})
    return [ZeroPolynomialInAlgebraicSetBridge]
end

function bridges(::Type{<:MOI.AbstractVectorFunction},
                 ::Type{<:PlusMinusSet})
    return [PlusMinusBridge]
end

"""
    bridgeable(c::JuMP.AbstractConstraint, F::Type{<:MOI.AbstractFunction},
               S::Type{<:MOI.AbstractSet})

Wrap the constraint `c` in `JuMP.BridgeableConstraint`s that may be needed to
bridge `F`-in-`S` constraints.
"""
function bridgeable end

function bridgeable(c::JuMP.AbstractConstraint,
                    F::Type{<:MOI.AbstractFunction},
                    S::Type{<:MOI.AbstractSet})
    bridge_types = bridges(F, S)
    for bridge_type in bridge_types
        c = BridgeableConstraint(c, bridge_type)
        concrete_bridge_type = MOIB.concrete_bridge_type(bridge_type{Float64},
                                                         F, S)
        for (FT, ST) in MOIB.added_constraint_types(concrete_bridge_type)
            c = bridgeable(c, FT, ST)
        end
    end
    return c
end

### @constraint/@SDconstraint macros ###

non_constant(a::Vector{<:Number}) = convert(Vector{AffExpr}, a)
non_constant(a::Vector{<:JuMP.AbstractJuMPScalar}) = a
non_constant_coefficients(p) = non_constant(coefficients(p))

## ZeroPoly
function JuMP.build_constraint(_error::Function, p::AbstractPolynomialLike,
                               s::ZeroPoly;
                               domain::AbstractSemialgebraicSet=FullSpace(),
                               kws...)
    coefs = non_constant_coefficients(p)
    monos = monomials(p)
    if domain isa BasicSemialgebraicSet
        # p(x) = 0 for all x in a basic semialgebraic set. We replace it by
        # p(x) ≤ 0 and p(x) ≥ 0 for all x in the basic semialgebraic set.
        # We need to determine the cone two use for `NonNegPoly` which is stored
        # in the `ext` field of the `model` so we need the `model` hence we need
        # to go to `JuMP.add_constraint`.

        # We need to recreate the full list of keyword arguments. `kws` is a
        # `Iterators.Pairs, `kws.data` is a `NamedTuple` and `kws.itr` is a
        # `Tuple`.
        all_kws = Iterators.Pairs(merge((domain=domain,), kws.data),
                                  (:domain, kws.itr...))
        return Constraint(_error, p, s, all_kws)
    else
        set = JuMP.moi_set(s, monos; domain=domain, kws...)
        constraint = JuMP.VectorConstraint(coefs, set, PolynomialShape(monos))
        return bridgeable(constraint, JuMP.moi_function_type(typeof(coefs)),
                          typeof(set))
    end
end
function JuMP.build_constraint(_error::Function, p::AbstractPolynomialLike,
                               s::MOI.EqualTo; kws...)
    return JuMP.build_constraint(_error, p-s.value, ZeroPoly(); kws...)
end

## NonNegPoly and PosDefPolyMatrix
# The `model` is not given in `JuMP.build_constraint` so we create a custom
# `Constraint` object and transform the `set` in `JuMP.add_constraint`.
struct Constraint{FT, PT, ST<:PolynomialSet, KWT<:Iterators.Pairs} <: JuMP.AbstractConstraint
    _error::FT
    polynomial_or_matrix::PT
    set::ST
    kws::KWT
end
function JuMP.build_constraint(_error::Function, polynomial_or_matrix,
                               set::Union{NonNegPoly, PosDefPolyMatrix};
                               kws...)
    return Constraint(_error, polynomial_or_matrix, set, kws)
end

# FIXME the domain will not appear in the printing, it should be a field of
#       `ZeroPoly` which is `FullSpace` by default
JuMP.reshape_set(::PlusMinusSet, ::PolynomialShape) = ZeroPoly()
function JuMP.add_constraint(model::JuMP.Model,
                             constraint::Constraint{<:Any, <:Any, ZeroPoly},
                             name::String = "")
    cone = getdefault(model, NonNegPoly())
    coefs = non_constant_coefficients(constraint.polynomial_or_matrix)
    monos = monomials(constraint.polynomial_or_matrix)
    set = PlusMinusSet(JuMP.moi_set(cone, monos; constraint.kws...))
    new_constraint = JuMP.VectorConstraint(coefs, set, PolynomialShape(monos))
    bridgeable_con = bridgeable(
        new_constraint, JuMP.moi_function_type(typeof(coefs)), typeof(set))
    return JuMP.add_constraint(model, bridgeable_con, name)
end

function JuMP.add_constraint(model::JuMP.Model, constraint::Constraint,
                             name::String = "")
    set = getdefault(model, constraint.set)
    new_constraint = JuMP.build_constraint(constraint._error,
                                           constraint.polynomial_or_matrix, set;
                                           constraint.kws...)
    return JuMP.add_constraint(model, new_constraint, name)
end

# NonNegPoly
function JuMP.build_constraint(_error::Function, p::AbstractPolynomialLike,
                               s::MOI.GreaterThan; kws...)
    return JuMP.build_constraint(_error, p-s.lower, NonNegPoly(); kws...)
end
function JuMP.build_constraint(_error::Function, p::AbstractPolynomialLike,
                               s::MOI.LessThan; kws...)
    return JuMP.build_constraint(_error, s.upper-p, NonNegPoly(); kws...)
end

# PosDefPolyMatrix
# there is already a method for AbstractMatrix in PSDCone in JuMP so we need a
# more specific here to avoid ambiguity
function JuMP.build_constraint(_error::Function,
                               p::AbstractMatrix{<:AbstractPolynomialLike},
                               s::PSDCone; kws...)
    return JuMP.build_constraint(_error, p, PosDefPolyMatrix(); kws...)
end
