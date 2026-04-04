# TermPlot.jl

`TermPlot.jl` is a pure Julia terminal plotting library for line charts, scatter plots, stacked bars, guide lines, dual y-axes, and simple linked panel layouts.

It is designed for direct REPL and script usage:

- Unicode terminal rendering
- ANSI colors when available
- `Date`, `DateTime`, and `ZonedDateTime` x-axes
- Dual y-axes in one plot area
- Simple multi-panel figures with linked axes

## Quick Start

```julia
using Dates
using TermPlot

fig = Figure(title="Quick Start")
panel!(fig, xlabel="Date", ylabel="Value", x_date_format=dateformat"yyyy-mm-dd")

x = [Date(2024, 1, 1) + Day(i) for i in 0:9]
line!(fig, x, cumsum(fill(1.0, 10)); label="Series", color=:cyan)
hline!(fig, 5.0; color=:gray, label="Reference")

display(fig)
```

## Public API

- `Figure`
- `panel!`
- `line!`
- `scatter!`
- `stackedbar!`
- `hline!`
- `vline!`
- `xlims!`
- `ylims!`
- `yscale!`
- `render`
- `render!`

## Examples

The documentation includes an organized examples section with separate pages for:

- line charts
- scatter plots
- reference lines
- dual-axis plots
- stacked bars
- linked layouts

## Development

Run tests with:

```bash
julia --project -e 'using Pkg; Pkg.test()'
```

Build docs with:

```bash
julia --project=docs docs/makedocs.jl
```
