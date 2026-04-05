# TermPlot.jl

[![Docs](https://img.shields.io/badge/docs-live-blue.svg)](https://rbeeli.github.io/TermPlot.jl/)
[![Docs build and deploy](https://github.com/rbeeli/TermPlot.jl/actions/workflows/Docs.yml/badge.svg)](https://github.com/rbeeli/TermPlot.jl/actions/workflows/Docs.yml)
[![Julia](https://img.shields.io/badge/julia-1.10%2B-9558B2.svg)](https://julialang.org/)
[![License](https://img.shields.io/github/license/rbeeli/TermPlot.jl.svg)](https://github.com/rbeeli/TermPlot.jl/blob/main/LICENSE)

Pure Julia terminal plotting with Unicode rasterization and ANSI colors.

`TermPlot.jl` is a lightweight plotting library for REPL and script output.
It focuses on readable terminal charts instead of heavyweight GUI backends.

Documentation: <https://rbeeli.github.io/TermPlot.jl/>

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/rbeeli/TermPlot.jl.git")
```

## Features

- line plots
- bar plots
- scatter plots
- stacked bar plots
- horizontal and vertical guide lines
- `Date`, `DateTime`, and `ZonedDateTime` x-axes
- manual axis limits
- flexible axis options
- `GridLayout` with weighted rows, weighted columns, and spanning panels
- rendering to any `IO`
- graceful handling of missing and non-finite data

## Quick Example

```julia
using Dates
using TermPlot

fig = Figure(title="Quick Example")
panel!(fig, xlabel="Date", ylabel="Value", x_date_format=dateformat"yyyy-mm-dd")

x = [Date(2024, 1, 1) + Day(i) for i in 0:9]
line!(fig, x, [1, 2, 3, 5, 4, 6, 7, 6, 8, 9]; label="Series", color=:cyan)
hline!(fig, 5; label="Reference", color=:gray)

display(fig)
```

## Documentation

Browse the full docs at <https://rbeeli.github.io/TermPlot.jl/>.

`GridLayout` powers the multi-panel layout system:

```julia
grid = GridLayout(2, 3; rowweights=[2, 1], colweights=[2, 1, 1], rowgap=1, colgap=2)
fig = Figure(grid; width=112, height=26)
main = panel!(fig, 1, 1:2; title="Main")
side = panel!(fig, 1:2, 3; title="Side")
lower = panel!(fig, 2, 1:2; title="Lower")
```

Examples live in the docs under `docs/src/examples/`, split by use case rather than duplicated as root-level scripts.

Repository layout:

- `src/`: package source
- `test/`: generic package tests
- `docs/`: DocumenterVitepress setup and organized examples

## Development

```bash
julia --project -e 'using Pkg; Pkg.test()'
julia --project=docs docs/makedocs.jl
```
