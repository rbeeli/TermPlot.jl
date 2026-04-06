# Messy Data

`TermPlot.jl` is strict about invalid configuration, but it is tolerant of
messy input samples during plotting. Missing and non-finite values are skipped,
while finite values outside explicit axis limits are clipped to the visible
frame.

```@setup messy_data
using TermPlot

fig = Figure(GridLayout(1, 2); title="Messy Data Handling", width=108, height=22)

skipped = panel!(fig, 1, 1; title="Skipped Samples", xlabel="Bucket", ylabel="Value")
clipped = panel!(fig, 1, 2; title="Clipped To Limits", xlabel="Bucket", ylabel="Value")

line!(
    skipped,
    1:8,
    [1.0, 1.4, NaN, 1.9, Inf, 1.6, 1.8, 1.7];
    label="Line",
    color=:cyan,
    marker=:circle,
)

scatter!(
    skipped,
    1:8,
    Any[0.8, missing, 1.0, 1.2, NaN, 1.1, 1.3, 1.25];
    label="Scatter",
    color=:yellow,
    marker=:diamond,
)

line!(
    clipped,
    0:8,
    [0.0, 0.4, 0.9, 1.3, 1.8, 2.2, 2.6, 3.1, 3.4];
    label="Finite data",
    color=:magenta,
)

hline!(clipped, 1.5; label="Center", color=:gray)
xlims!(clipped, 1, 7)
ylims!(clipped, 0.5, 2.5)
```

```julia
using TermPlot

fig = Figure(GridLayout(1, 2); title="Messy Data Handling", width=108, height=22)

skipped = panel!(fig, 1, 1; title="Skipped Samples", xlabel="Bucket", ylabel="Value")
clipped = panel!(fig, 1, 2; title="Clipped To Limits", xlabel="Bucket", ylabel="Value")

line!(skipped, 1:8, [1.0, 1.4, NaN, 1.9, Inf, 1.6, 1.8, 1.7]; label="Line", color=:cyan, marker=:circle)
scatter!(skipped, 1:8, Any[0.8, missing, 1.0, 1.2, NaN, 1.1, 1.3, 1.25]; label="Scatter", color=:yellow, marker=:diamond)

line!(clipped, 0:8, [0.0, 0.4, 0.9, 1.3, 1.8, 2.2, 2.6, 3.1, 3.4]; label="Finite data", color=:magenta)
hline!(clipped, 1.5; label="Center", color=:gray)
xlims!(clipped, 1, 7)
ylims!(clipped, 0.5, 2.5)

display(fig)
```

```@example messy_data; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## What Happens

- `missing`, `NaN`, and `Inf` samples are skipped before rasterization
- finite line and stem segments that cross the current limits are clipped to the frame
- fully hidden stacked-bar layers are dropped instead of painting phantom edge strips

That lets you inspect imperfect research data without introducing fake plotted
values.
