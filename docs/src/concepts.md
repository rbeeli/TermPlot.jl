# Concepts

`TermPlot.jl` has a small core model:

- a `Figure` is the top-level chart container
- a `Panel` is one subplot inside the figure
- series are appended to panels with `line!`, `stem!`, `scatter!`, `bar!`, `stackedbar!`, `hline!`, and `vline!`
- rendering turns the whole figure into terminal text or SVG

If you keep that model in mind, the rest of the API stays straightforward.

## Figure And Panel

`Figure` owns:

- the overall title
- output size
- the `GridLayout`
- linked-axis settings
- whether the combined legend is shown

`Panel` owns:

- one x-axis
- one left y-axis
- one right y-axis
- the panel title
- the series assigned to that subplot

In normal use you create figures directly and obtain panels from `panel!`:

```julia
using TermPlot

fig = Figure(GridLayout(2, 2); width=96, height=24)

top_left = panel!(fig, 1, 1; title="Top Left", xlabel="x", ylabel="y")
bottom = panel!(fig, 2, 1:2; title="Bottom", xlabel="x", ylabel="spread")
```

## Current Panel Behavior

`panel!` always makes the created or replaced panel the figure's current panel.
Plotting calls that target the figure then append to that current panel.

```julia
using TermPlot

fig = Figure(GridLayout(1, 2); width=84, height=18)

left = panel!(fig, 1, 1; title="Left", xlabel="x", ylabel="y")
line!(fig, 1:4, [1.0, 2.0, 1.5, 3.0]; label="Goes left")

right = panel!(fig, 1, 2; title="Right", xlabel="x", ylabel="y")
line!(fig, 1:4, [0.5, 0.7, 0.6, 0.9]; label="Now goes right")

line!(left, 1:4, [1.2, 1.8, 1.6, 2.4]; label="Explicit left")
```

This is convenient for single-panel scripts. In multi-panel figures, keep panel
handles and target them directly once the layout gets more than trivial.

## Spans, Replacement, And Overlap

`panel!` accepts either integers or contiguous `UnitRange`s for `row` and
`col`, so panels can span multiple grid cells.

```julia
main = panel!(fig, 1:2, 1:2; title="Main")
side = panel!(fig, 1:2, 3; title="Side")
```

Placement rules are strict:

- calling `panel!` on the exact same placement replaces that panel
- partially overlapping a different existing placement raises an error
- you can retrieve panels again with `fig[row, col]` or `fig[rows, cols]`

That keeps the layout model deterministic and avoids ambiguous overlapping
subplots.

## Layout Tracks, Seams, And Alignment

`GridLayout` has three core responsibilities:

- track sizes via `rowweights` and `colweights`
- boundaries via `rowseams` and `colseams`
- optional plot-area alignment via `rowaligns` and `colaligns`

Useful rules of thumb:

- use `GridSeam(:separate; gap=...)` for visible gaps between panels
- use `GridSeam(:adjacent)` when panels should share a border
- use `rowaligns=:all` or `colaligns=:all` when neighboring panels should line up plot frames and tick budgets
- use vectors like `colaligns=[:left, :left, :right]` when only some tracks should align together

For worked examples, see [Layouts](examples/layouts.md).

## When To Keep Panel Handles

You can get away with plotting against the figure directly when:

- there is only one panel
- you are building one panel at a time in strict sequence

Keep explicit panel handles when:

- the figure has multiple panels
- you use spans
- you revisit an earlier panel later in the script
- you mix left and right y-axis content and want the call site to stay obvious

That pattern tends to keep research notebooks and scripts easier to audit.
