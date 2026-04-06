# Line Charts

Line charts are the default starting point for `TermPlot.jl`.

The chart below is generated during the docs build.

```@setup basic_line_plots
using Dates
using TermPlot

fig = Figure(title="Basic Example", width=112, height=24);
panel!(
    fig,
    title="Portfolio",
    xlabel="Date",
    ylabel="Normalized level",
    x_date_format=dateformat"yyyy-mm-dd",
);

x = [Date(2024, 1, 1) + Day(i) for i in 0:11];

line!(
    fig,
    x,
    [1.0, 1.03, 1.05, 1.01, 1.08, 1.12, 1.10, 1.15, 1.18, 1.16, 1.20, 1.24];
    label="Strategy",
    color=:cyan,
);

line!(
    fig,
    x,
    [1.0, 1.01, 1.02, 1.02, 1.03, 1.04, 1.04, 1.05, 1.05, 1.06, 1.07, 1.08];
    label="Benchmark",
    color=:blue,
);

hline!(fig, 1.0; color=:gray, label="Baseline");

```

```julia
using Dates
using TermPlot

fig = Figure(title="Basic Example", width=112, height=24)
panel!(
    fig,
    title="Portfolio",
    xlabel="Date",
    ylabel="Normalized level",
    x_date_format=dateformat"yyyy-mm-dd",
)

x = [Date(2024, 1, 1) + Day(i) for i in 0:11]

line!(
    fig,
    x,
    [1.0, 1.03, 1.05, 1.01, 1.08, 1.12, 1.10, 1.15, 1.18, 1.16, 1.20, 1.24];
    label="Strategy",
    color=:cyan,
)

line!(
    fig,
    x,
    [1.0, 1.01, 1.02, 1.02, 1.03, 1.04, 1.04, 1.05, 1.05, 1.06, 1.07, 1.08];
    label="Benchmark",
    color=:blue,
)

hline!(fig, 1.0; color=:gray, label="Baseline")

display(fig)
```

```@example basic_line_plots; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Markers

Line series can place markers on each data point via `marker`.
Named options such as `:diamond`, `:circle`, `:square`, and `:cross` are built in, and you can also pass a single Unicode character directly.

```@setup line_markers
using TermPlot

fig = Figure(title="Line Markers", width=112, height=24);
panel!(
    fig,
    title="Markers On Line Series",
    xlabel="Bucket",
    ylabel="Signal",
);

x = 1:6;

line!(fig, x, [0.25, 0.52, 0.48, 0.76, 0.71, 0.88]; label="diamond", color=:cyan, marker=:diamond);
line!(fig, x, [0.18, 0.30, 0.40, 0.51, 0.57, 0.63]; label="circle", color=:blue, marker=:circle);
line!(fig, x, [0.62, 0.58, 0.67, 0.60, 0.73, 0.69]; label="custom", color=:yellow, marker='▲');
```

```julia
using TermPlot

fig = Figure(title="Line Markers", width=112, height=24)
panel!(
    fig,
    title="Markers On Line Series",
    xlabel="Bucket",
    ylabel="Signal",
)

x = 1:6

line!(fig, x, [0.25, 0.52, 0.48, 0.76, 0.71, 0.88]; label="diamond", color=:cyan, marker=:diamond)
line!(fig, x, [0.18, 0.30, 0.40, 0.51, 0.57, 0.63]; label="circle", color=:blue, marker=:circle)
line!(fig, x, [0.62, 0.58, 0.67, 0.60, 0.73, 0.69]; label="custom", color=:yellow, marker='▲')

display(fig)
```

```@example line_markers; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Step Modes

Line series can also render as step plots via `step=:pre`, `step=:mid`, or `step=:post`.
Using the same data in separate linked panels makes the interpolation difference easier to compare.
The filled markers show the exact underlying sample locations.

```@setup step_line_plots
using TermPlot

fig = Figure(GridLayout(3, 1); title="Step Modes", width=112, height=34, linkx=true, linky=true, legend=false);
post = panel!(fig, 1, 1; title="Post", xlabel="Bucket", ylabel="Allocation");
mid = panel!(fig, 2, 1; title="Mid", xlabel="Bucket", ylabel="Allocation");
pre = panel!(fig, 3, 1; title="Pre", xlabel="Bucket", ylabel="Allocation");

x = 1:7;
values = [0.20, 0.55, 0.35, 0.72, 0.50, 0.84, 0.68];

line!(post, x, values; color=:cyan, step=:post, marker='●');
line!(mid, x, values; color=:yellow, step=:mid, marker='●');
line!(pre, x, values; color=:magenta, step=:pre, marker='●');
```

```julia
using TermPlot

fig = Figure(GridLayout(3, 1); title="Step Modes", width=112, height=34, linkx=true, linky=true, legend=false)
post = panel!(fig, 1, 1; title="Post", xlabel="Bucket", ylabel="Allocation")
mid = panel!(fig, 2, 1; title="Mid", xlabel="Bucket", ylabel="Allocation")
pre = panel!(fig, 3, 1; title="Pre", xlabel="Bucket", ylabel="Allocation")

x = 1:7
values = [0.20, 0.55, 0.35, 0.72, 0.50, 0.84, 0.68]

line!(post, x, values; color=:cyan, step=:post, marker='●')
line!(mid, x, values; color=:yellow, step=:mid, marker='●')
line!(pre, x, values; color=:magenta, step=:pre, marker='●')

display(fig)
```

```@example step_line_plots; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```
