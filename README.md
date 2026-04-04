# TermPlot.jl

Pure Julia terminal plotting with Unicode rasterization and ANSI colors.

`TermPlot.jl` is a lightweight plotting library for REPL and script output.
It focuses on readable terminal charts instead of heavyweight GUI backends.

## Features

- line plots
- scatter plots
- stacked bar plots
- horizontal and vertical guide lines
- `Date`, `DateTime`, and `ZonedDateTime` x-axes
- manual axis limits
- dual y-axes
- linked multi-panel layouts
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
