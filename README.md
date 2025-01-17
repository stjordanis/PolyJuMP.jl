# PolyJuMP

| **Build Status** |
|:----------------:|
| [![Build Status][build-img]][build-url] [![Build Status][winbuild-img]][winbuild-url] |
| [![Coveralls branch][coveralls-img]][coveralls-url] [![Codecov branch][codecov-img]][codecov-url] |

PolyJuMP is an extension to [JuMP](https://github.com/JuliaOpt/JuMP.jl) for formulating and solving polynomial optimization problems. These problems can then be solved using [Sum of Squares Programming](https://github.com/JuliaOpt/SumOfSquares.jl).

## Documentation

- [**STABLE**][docs-stable-url] &mdash; **most recently tagged version of [SumOfSquares](https://github.com/JuliaOpt/SumOfSquares.jl)' documentation.**
- [**LATEST**][docs-latest-url] &mdash; *in-development version of [SumOfSquares](https://github.com/JuliaOpt/SumOfSquares.jl)' documentation.*

Some presentations on, or using, PolyJuMP:
  * Benoît Legat at [CNLS 2019](https://cnls.lanl.gov/External/showtalksummary.php?selection=7768) [[Slides](https://drive.google.com/open?id=1kNF18C7RY2zi7jcZBMO1PRXtHuvVTFPn)]
  * Benoît Legat at [EURO 2019](https://www.euro2019dublin.com/) [[Slides](https://drive.google.com/open?id=1Wry56NzzL4QBRSwuhP4AlKOe2i2FL7dk)]
  * Benoît Legat at [juliaday Nantes 2019](https://julialang.univ-nantes.fr/programme/) [[Slides](https://drive.google.com/open?id=1pN3G9Pr8jbzK9EEaJ9a6p_qKwSbxb2bo)]
  * Benoît Legat at [Summer School on Numerical Computing in Algebraic Geometry 2018](https://www.mis.mpg.de/calendar/conferences/2018/nc2018.html) [[Poster](https://drive.google.com/open?id=1pf9rdoVEjAnD164rptLki1AG0AH4i88M)]
  * Benoît Legat at [The First Annual JuMP-dev Workshop 2017](http://www.juliaopt.org/meetings/mit2017/) [[Slides](http://www.juliaopt.org/meetings/mit2017/legat.pdf)] [[Video](https://youtu.be/kyo72yWYr54)]
  * [Joey Huchette at SIAM Opt 2017](https://docs.google.com/presentation/d/1ASfjB1TdLJmYxT0b6rnyGh9eLbMc-66bTOt3_3yvc90/edit?usp=sharing)

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-stable-url]: https://juliaopt.github.io/SumOfSquares.jl/stable
[docs-latest-url]: https://juliaopt.github.io/SumOfSquares.jl/latest

[build-img]: https://travis-ci.org/JuliaOpt/PolyJuMP.jl.svg?branch=master
[build-url]: https://travis-ci.org/JuliaOpt/PolyJuMP.jl
[winbuild-img]: https://ci.appveyor.com/api/projects/status/2y6dc0j2xk4aa4v7?svg=true
[winbuild-url]: https://ci.appveyor.com/project/JuliaOpt/polyjump-jl
[coveralls-img]: https://coveralls.io/repos/github/JuliaOpt/PolyJuMP.jl/badge.svg?branch=master
[coveralls-url]: https://coveralls.io/github/JuliaOpt/PolyJuMP.jl?branch=master
[codecov-img]: http://codecov.io/github/JuliaOpt/PolyJuMP.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/JuliaOpt/PolyJuMP.jl?branch=master
