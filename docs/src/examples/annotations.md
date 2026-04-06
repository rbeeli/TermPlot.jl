# Annotations

Annotations let you place arbitrary Unicode text directly inside the plot area.

- Use axis-space coordinates with `xref=:x` and `yref=:y` or `:y2`
- Use plot-relative coordinates with `xref=:paper` and `yref=:paper`
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

```@setup annotations_paper
using TermPlot

fig = Figure(title="Plot-Relative Annotation Example", width=112, height=24, legend=false);
panel!(fig; title="Anchored To The Plot Area", xlabel="Bucket", ylabel="Signal");

x = 1:8;
signal = [0.15, 0.28, 0.41, 0.39, 0.58, 0.64, 0.73, 0.81];

line!(fig, x, signal; color=:cyan, marker=:circle);
annotate!(fig, 0.0, 1.0, "top left"; xref=:paper, yref=:paper, xanchor=:left, yanchor=:top, color=:yellow);
annotate!(fig, 1.0, 1.0, "top right"; xref=:paper, yref=:paper, xanchor=:right, yanchor=:top, color=:green);
annotate!(fig, 0.0, 0.0, "bottom left"; xref=:paper, yref=:paper, xanchor=:left, yanchor=:bottom, color=:magenta);
annotate!(fig, 0.5, 0.0, "bottom center"; xref=:paper, yref=:paper, xanchor=:center, yanchor=:bottom, color=:red);

ylims!(fig, 0, 1);
```

```julia
using TermPlot

fig = Figure(title="Plot-Relative Annotation Example", width=112, height=24, legend=false)
panel!(fig; title="Anchored To The Plot Area", xlabel="Bucket", ylabel="Signal")

x = 1:8
signal = [0.15, 0.28, 0.41, 0.39, 0.58, 0.64, 0.73, 0.81]

line!(fig, x, signal; color=:cyan, marker=:circle)
annotate!(fig, 0.0, 1.0, "top left"; xref=:paper, yref=:paper, xanchor=:left, yanchor=:top, color=:yellow)
annotate!(fig, 1.0, 1.0, "top right"; xref=:paper, yref=:paper, xanchor=:right, yanchor=:top, color=:green)
annotate!(fig, 0.0, 0.0, "bottom left"; xref=:paper, yref=:paper, xanchor=:left, yanchor=:bottom, color=:magenta)
annotate!(fig, 0.5, 0.0, "bottom center"; xref=:paper, yref=:paper, xanchor=:center, yanchor=:bottom, color=:red)

ylims!(fig, 0, 1)

display(fig)
```

```@example annotations_paper; ansicolor=true
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
