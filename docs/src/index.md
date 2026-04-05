# TermPlot.jl

`TermPlot.jl` is a pure Julia terminal plotting library for line charts, bar charts, scatter plots, stacked bars, guide lines, flexible axis control, and seam-aware `GridLayout` multi-panel figures.

It is designed for direct REPL and script usage:

- Unicode terminal rendering
- ANSI colors when available
- `Date`, `DateTime`, and `ZonedDateTime` x-axes
- Dual y-axes in one plot area
- Weighted multi-panel figures with row and column spans
- Optional aligned plot areas via `rowaligns` and `colaligns`
- Adjacent subplots controlled seam-by-seam

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
- `GridSeam`
- `GridLayout`
- `panel!`
- `line!`
- `bar!`
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
- bar charts
- stacked bars
- scatter plots
- reference lines
- axis options
- layouts
- labels and legends

## Development

Run tests with:

```bash
julia --project -e 'using Pkg; Pkg.test()'
```

Build docs with:

```bash
julia --project=docs docs/makedocs.jl
```
