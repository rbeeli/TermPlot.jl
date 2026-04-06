# Annotations

Annotations let you place arbitrary Unicode text directly inside the plot area.

- Use axis-space coordinates with `xref=:x` and `yref=:y` or `:y2`
- Use plot-relative coordinates with `xref=:paper` and `yref=:paper`
- Mix axis and plot-relative references independently on x and y
- Control the attached point with `xanchor` and `yanchor`
- Control multi-line text justification with `align`

The charts below are generated during the docs build.

## Axis Coordinates

```@setup annotations_axis
using Dates
using TermPlot

fig = Figure(title="Axis Annotation Example", width=112, height=24, legend=false);
panel!(fig; title="Annotated Breakout", xlabel="Date", ylabel="Close", x_date_format=dateformat"yyyy-mm-dd");

x = [Date(2024, 1, 1) + Day(i) for i in 0:9];
close = [101, 102, 103, 105, 104, 106, 107, 106, 108, 110];

line!(fig, x, close; color=:cyan);
annotate!(fig, Date(2024, 1, 4), 105.2, "Entry"; xanchor=:left, yanchor=:bottom, color=:yellow);
annotate!(fig, Date(2024, 1, 8), 105.8, "Retest"; xanchor=:right, yanchor=:top, color=:magenta);

ylims!(fig, 100, 111);
```

```julia
using Dates
using TermPlot

fig = Figure(title="Axis Annotation Example", width=112, height=24, legend=false)
panel!(fig; title="Annotated Breakout", xlabel="Date", ylabel="Close", x_date_format=dateformat"yyyy-mm-dd")

x = [Date(2024, 1, 1) + Day(i) for i in 0:9]
close = [101, 102, 103, 105, 104, 106, 107, 106, 108, 110]

line!(fig, x, close; color=:cyan)
annotate!(fig, Date(2024, 1, 4), 105.2, "Entry"; xanchor=:left, yanchor=:bottom, color=:yellow)
annotate!(fig, Date(2024, 1, 8), 105.8, "Retest"; xanchor=:right, yanchor=:top, color=:magenta)

ylims!(fig, 100, 111)

display(fig)
```

```@example annotations_axis; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Plot-Relative Coordinates

Use `xref=:paper` and `yref=:paper` when you want the annotation to stay pinned
to the plot area instead of moving with the data range.
The example below covers the full perimeter placement set in plot-relative
coordinates: the four corners plus the midpoint of each edge.

```@setup annotations_paper_perimeter
using TermPlot

fig = Figure(title="Paper-Coordinate Perimeter Positions", width=112, height=26, legend=false);
panel!(fig; title="Corners And Edge Midpoints", xlabel="Bucket", ylabel="Signal");

x = 1:8;
signal = [0.18, 0.26, 0.38, 0.35, 0.55, 0.62, 0.74, 0.82];

line!(fig, x, signal; color=:cyan, marker=:circle);
annotate!(fig, 0.0, 1.0, "top left"; xref=:paper, yref=:paper, xanchor=:left, yanchor=:top, color=:yellow);
annotate!(fig, 0.5, 1.0, "top"; xref=:paper, yref=:paper, xanchor=:center, yanchor=:top, align=:center, color=:green);
annotate!(fig, 1.0, 1.0, "top right"; xref=:paper, yref=:paper, xanchor=:right, yanchor=:top, color=:magenta);
annotate!(fig, 0.0, 0.5, "mid left"; xref=:paper, yref=:paper, xanchor=:left, yanchor=:middle, color=:red);
annotate!(fig, 1.0, 0.5, "mid right"; xref=:paper, yref=:paper, xanchor=:right, yanchor=:middle, color=:blue);
annotate!(fig, 0.0, 0.0, "bottom left"; xref=:paper, yref=:paper, xanchor=:left, yanchor=:bottom, color=:yellow);
annotate!(fig, 0.5, 0.0, "bottom"; xref=:paper, yref=:paper, xanchor=:center, yanchor=:bottom, align=:center, color=:green);
annotate!(fig, 1.0, 0.0, "bottom right"; xref=:paper, yref=:paper, xanchor=:right, yanchor=:bottom, color=:magenta);

ylims!(fig, 0, 1);
```

```julia
using TermPlot

fig = Figure(title="Paper-Coordinate Perimeter Positions", width=112, height=26, legend=false)
panel!(fig; title="Corners And Edge Midpoints", xlabel="Bucket", ylabel="Signal")

x = 1:8
signal = [0.18, 0.26, 0.38, 0.35, 0.55, 0.62, 0.74, 0.82]

line!(fig, x, signal; color=:cyan, marker=:circle)
annotate!(fig, 0.0, 1.0, "top left"; xref=:paper, yref=:paper, xanchor=:left, yanchor=:top, color=:yellow)
annotate!(fig, 0.5, 1.0, "top"; xref=:paper, yref=:paper, xanchor=:center, yanchor=:top, align=:center, color=:green)
annotate!(fig, 1.0, 1.0, "top right"; xref=:paper, yref=:paper, xanchor=:right, yanchor=:top, color=:magenta)
annotate!(fig, 0.0, 0.5, "mid left"; xref=:paper, yref=:paper, xanchor=:left, yanchor=:middle, color=:red)
annotate!(fig, 1.0, 0.5, "mid right"; xref=:paper, yref=:paper, xanchor=:right, yanchor=:middle, color=:blue)
annotate!(fig, 0.0, 0.0, "bottom left"; xref=:paper, yref=:paper, xanchor=:left, yanchor=:bottom, color=:yellow)
annotate!(fig, 0.5, 0.0, "bottom"; xref=:paper, yref=:paper, xanchor=:center, yanchor=:bottom, align=:center, color=:green)
annotate!(fig, 1.0, 0.0, "bottom right"; xref=:paper, yref=:paper, xanchor=:right, yanchor=:bottom, color=:magenta)

ylims!(fig, 0, 1)

display(fig)
```

```@example annotations_paper_perimeter; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Mixed Axis And Plot References

`xref` and `yref` can be mixed independently. This is useful when you want text
to track a data value on one axis while staying pinned to a fixed edge on the
other axis.

```@setup annotations_mixed_refs
using TermPlot

fig = Figure(GridLayout(1, 2); title="Mixed Annotation References", width=112, height=24, legend=false);

left = panel!(fig, 1, 1; title="`xref=:paper`, `yref=:y`", xlabel="Bucket", ylabel="Score");
right = panel!(fig, 1, 2; title="`xref=:x`, `yref=:paper`", xlabel="Bucket", ylabel="Score");

x = 1:8;
score = [0.18, 0.24, 0.37, 0.31, 0.56, 0.63, 0.71, 0.84];

line!(left, x, score; color=:cyan);
annotate!(left, 0.0, 0.25, "floor"; xref=:paper, yref=:y, xanchor=:left, yanchor=:middle, color=:yellow);
annotate!(left, 0.0, 0.75, "target"; xref=:paper, yref=:y, xanchor=:left, yanchor=:middle, color=:magenta);

line!(right, x, score; color=:cyan);
annotate!(right, 3, 1.0, "phase 1"; xref=:x, yref=:paper, xanchor=:center, yanchor=:top, color=:yellow);
annotate!(right, 6, 0.0, "phase 2"; xref=:x, yref=:paper, xanchor=:center, yanchor=:bottom, color=:green);

ylims!(left, 0, 1);
ylims!(right, 0, 1);
```

```julia
using TermPlot

fig = Figure(GridLayout(1, 2); title="Mixed Annotation References", width=112, height=24, legend=false)

left = panel!(fig, 1, 1; title="`xref=:paper`, `yref=:y`", xlabel="Bucket", ylabel="Score")
right = panel!(fig, 1, 2; title="`xref=:x`, `yref=:paper`", xlabel="Bucket", ylabel="Score")

x = 1:8
score = [0.18, 0.24, 0.37, 0.31, 0.56, 0.63, 0.71, 0.84]

line!(left, x, score; color=:cyan)
annotate!(left, 0.0, 0.25, "floor"; xref=:paper, yref=:y, xanchor=:left, yanchor=:middle, color=:yellow)
annotate!(left, 0.0, 0.75, "target"; xref=:paper, yref=:y, xanchor=:left, yanchor=:middle, color=:magenta)

line!(right, x, score; color=:cyan)
annotate!(right, 3, 1.0, "phase 1"; xref=:x, yref=:paper, xanchor=:center, yanchor=:top, color=:yellow)
annotate!(right, 6, 0.0, "phase 2"; xref=:x, yref=:paper, xanchor=:center, yanchor=:bottom, color=:green)

ylims!(left, 0, 1)
ylims!(right, 0, 1)

display(fig)
```

```@example annotations_mixed_refs; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Anchor Combinations

The anchor determines which point of the text box is attached to the target
coordinate. In the grid below, every panel uses the same point and the same
text. Only `xanchor` and `yanchor` change.

```@setup annotations_anchor_grid
using TermPlot

fig = Figure(GridLayout(3, 3); title="Annotation Anchor Grid", width=112, height=64, legend=false);

anchors = [
    (:left, :top, "left/top"),
    (:center, :top, "center/top"),
    (:right, :top, "right/top"),
    (:left, :middle, "left/middle"),
    (:center, :middle, "center/middle"),
    (:right, :middle, "right/middle"),
    (:left, :bottom, "left/bottom"),
    (:center, :bottom, "center/bottom"),
    (:right, :bottom, "right/bottom"),
];

for (ix, (xanchor, yanchor, title)) in pairs(anchors)
    row = fld(ix - 1, 3) + 1
    col = mod1(ix, 3)
    panel = panel!(fig, row, col; title=title, xlabel="x", ylabel="y")
    scatter!(panel, [0.5], [0.5]; color=:cyan, marker=:diamond)
    annotate!(panel, 0.5, 0.5, "Annotation\nLabel"; xanchor=xanchor, yanchor=yanchor, color=:yellow)
    xlims!(panel, 0, 1)
    ylims!(panel, 0, 1)
end
```

```julia
using TermPlot

fig = Figure(GridLayout(3, 3); title="Annotation Anchor Grid", width=112, height=64, legend=false)

anchors = [
    (:left, :top, "left/top"),
    (:center, :top, "center/top"),
    (:right, :top, "right/top"),
    (:left, :middle, "left/middle"),
    (:center, :middle, "center/middle"),
    (:right, :middle, "right/middle"),
    (:left, :bottom, "left/bottom"),
    (:center, :bottom, "center/bottom"),
    (:right, :bottom, "right/bottom"),
]

for (ix, (xanchor, yanchor, title)) in pairs(anchors)
    row = fld(ix - 1, 3) + 1
    col = mod1(ix, 3)
    panel = panel!(fig, row, col; title=title, xlabel="x", ylabel="y")
    scatter!(panel, [0.5], [0.5]; color=:cyan, marker=:diamond)
    annotate!(panel, 0.5, 0.5, "Annotation\nLabel"; xanchor=xanchor, yanchor=yanchor, color=:yellow)
    xlims!(panel, 0, 1)
    ylims!(panel, 0, 1)
end

display(fig)
```

```@example annotations_anchor_grid; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Alignment Modes

`align` only affects multi-line annotations. The anchor stays the same in all
three panels below; only the line justification changes.

```@setup annotations_alignment
using TermPlot

fig = Figure(GridLayout(1, 3); title="Annotation Alignment", width=112, height=20, legend=false);

specs = [
    (:left, "align=:left", :yellow),
    (:center, "align=:center", :green),
    (:right, "align=:right", :magenta),
];

for (col, (align, title, color)) in pairs(specs)
    panel = panel!(fig, 1, col; title=title, xlabel="x", ylabel="y")
    scatter!(panel, [0.5], [0.5]; color=:cyan, marker=:diamond)
    annotate!(panel, 0.5, 0.5, "signal\nmid\nx"; xanchor=:center, yanchor=:middle, align=align, color=color)
    xlims!(panel, 0, 1)
    ylims!(panel, 0, 1)
end
```

```julia
using TermPlot

fig = Figure(GridLayout(1, 3); title="Annotation Alignment", width=112, height=20, legend=false)

specs = [
    (:left, "align=:left", :yellow),
    (:center, "align=:center", :green),
    (:right, "align=:right", :magenta),
]

for (col, (align, title, color)) in pairs(specs)
    panel = panel!(fig, 1, col; title=title, xlabel="x", ylabel="y")
    scatter!(panel, [0.5], [0.5]; color=:cyan, marker=:diamond)
    annotate!(panel, 0.5, 0.5, "signal\nmid\nx"; xanchor=:center, yanchor=:middle, align=align, color=color)
    xlims!(panel, 0, 1)
    ylims!(panel, 0, 1)
end

display(fig)
```

```@example annotations_alignment; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Multiline Text, Alignment, And `yref=:y2`

`align` is most visible with multi-line text. In the example below, the left
annotation is right-aligned within its two-line box, and the right annotation
is attached to the right y-axis via `yref=:y2`.

```@setup annotations_multiline
using TermPlot

fig = Figure(title="Multiline Annotation Example", width=112, height=24, legend=false);
panel!(fig; title="Unicode And Right-Axis Notes", xlabel="Bucket", ylabel="Signal", ylabel_right="Risk");

x = 1:8;
signal = [0.28, 0.40, 0.34, 0.56, 0.62, 0.59, 0.74, 0.88];
risk = [8, 9, 11, 10, 13, 15, 14, 18];

line!(fig, x, signal; color=:cyan);
line!(fig, x, risk; color=:red, yside=:right);
annotate!(fig, 4, 0.58, "alpha\nwatch"; xanchor=:right, yanchor=:bottom, align=:right, color=:yellow);
annotate!(fig, 8, 17.5, "猫\nrisk"; yref=:y2, xanchor=:right, yanchor=:top, align=:center, color=:green);

ylims!(fig, 0.2, 1.0);
ylims!(fig, 0, 20; yside=:right);
```

```julia
using TermPlot

fig = Figure(title="Multiline Annotation Example", width=112, height=24, legend=false)
panel!(fig; title="Unicode And Right-Axis Notes", xlabel="Bucket", ylabel="Signal", ylabel_right="Risk")

x = 1:8
signal = [0.28, 0.40, 0.34, 0.56, 0.62, 0.59, 0.74, 0.88]
risk = [8, 9, 11, 10, 13, 15, 14, 18]

line!(fig, x, signal; color=:cyan)
line!(fig, x, risk; color=:red, yside=:right)
annotate!(fig, 4, 0.58, "alpha\nwatch"; xanchor=:right, yanchor=:bottom, align=:right, color=:yellow)
annotate!(fig, 8, 17.5, "猫\nrisk"; yref=:y2, xanchor=:right, yanchor=:top, align=:center, color=:green)

ylims!(fig, 0.2, 1.0)
ylims!(fig, 0, 20; yside=:right)

display(fig)
```

```@example annotations_multiline; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```
