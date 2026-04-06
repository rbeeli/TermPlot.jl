# Labels And Legends

This page focuses on panel headers: centered legends, wrapped left and right y-axis labels, and the `legend=false` option.

The charts below are generated during the docs build.

## Wrapped Header Block

```@setup labels_legends_wrapped
using Dates
using TermPlot

fig = Figure(title="Header Layout Example", width=112, height=24);
panel!(
    fig;
    title="Legend And Labels",
    xlabel="Date",
    ylabel="Left axis contribution label",
    ylabel_right="Right axis drawdown label",
    x_date_format=dateformat"yyyy-mm-dd",
);

x = [Date(2024, 3, 1) + Day(i) for i in 0:7];

line!(fig, x, [1.00, 1.03, 1.05, 1.04, 1.08, 1.12, 1.10, 1.14]; label="Strategy", color=:cyan);
line!(fig, x, [0.99, 1.00, 1.02, 1.01, 1.03, 1.04, 1.05, 1.06]; label="Benchmark", color=:blue);
scatter!(fig, x, [1.01, 1.02, 1.03, 1.03, 1.05, 1.06, 1.08, 1.09]; label="Signals", color=:yellow, marker="diamond");
line!(fig, x, [-4, -3, -5, -4, -6, -5, -7, -6]; label="Drawdown", color=:red, yside=:right);
hline!(fig, 1.0; label="Baseline", color=:gray);

ylims!(fig, 0.95, 1.16);
ylims!(fig, -8, 0; yside=:right);
```

```julia
using Dates
using TermPlot

fig = Figure(title="Header Layout Example", width=112, height=24)
panel!(
    fig;
    title="Legend And Labels",
    xlabel="Date",
    ylabel="Left axis contribution label",
    ylabel_right="Right axis drawdown label",
    x_date_format=dateformat"yyyy-mm-dd",
)

x = [Date(2024, 3, 1) + Day(i) for i in 0:7]

line!(fig, x, [1.00, 1.03, 1.05, 1.04, 1.08, 1.12, 1.10, 1.14]; label="Strategy", color=:cyan)
line!(fig, x, [0.99, 1.00, 1.02, 1.01, 1.03, 1.04, 1.05, 1.06]; label="Benchmark", color=:blue)
scatter!(fig, x, [1.01, 1.02, 1.03, 1.03, 1.05, 1.06, 1.08, 1.09]; label="Signals", color=:yellow, marker="diamond")
line!(fig, x, [-4, -3, -5, -4, -6, -5, -7, -6]; label="Drawdown", color=:red, yside=:right)
hline!(fig, 1.0; label="Baseline", color=:gray)

ylims!(fig, 0.95, 1.16)
ylims!(fig, -8, 0; yside=:right)

display(fig)
```

```@example labels_legends_wrapped; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Labels Without A Legend

```@setup labels_legends_hidden
using Dates
using TermPlot

fig = Figure(title="Label-Only Header", width=112, height=24, legend=false);
panel!(
    fig;
    title="Legend Disabled",
    xlabel="Date",
    ylabel="Exposure label",
    ylabel_right="Risk label",
    x_date_format=dateformat"yyyy-mm-dd",
);

x = [Date(2024, 4, 1) + Day(i) for i in 0:5];

line!(fig, x, [0.42, 0.47, 0.51, 0.49, 0.54, 0.58]; label="Exposure", color=:magenta);
line!(fig, x, [12, 11, 13, 10, 14, 12]; label="Risk", color=:green, yside=:right);

ylims!(fig, 0.35, 0.65);
ylims!(fig, 8, 16; yside=:right);
```

```julia
using Dates
using TermPlot

fig = Figure(title="Label-Only Header", width=112, height=24, legend=false)
panel!(
    fig;
    title="Legend Disabled",
    xlabel="Date",
    ylabel="Exposure label",
    ylabel_right="Risk label",
    x_date_format=dateformat"yyyy-mm-dd",
)

x = [Date(2024, 4, 1) + Day(i) for i in 0:5]

line!(fig, x, [0.42, 0.47, 0.51, 0.49, 0.54, 0.58]; label="Exposure", color=:magenta)
line!(fig, x, [12, 11, 13, 10, 14, 12]; label="Risk", color=:green, yside=:right)

ylims!(fig, 0.35, 0.65)
ylims!(fig, 8, 16; yside=:right)

display(fig)
```

```@example labels_legends_hidden; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Wide Unicode Labels And Markers

This example keeps a fixed figure width while using width-2 Unicode glyphs in
both categorical x labels and point markers.

```@setup labels_legends_unicode
using TermPlot

fig = Figure(GridLayout(2, 1); title="Wide Unicode Support", width=112, height=24, legend=false);

top = panel!(fig, 1, 1; title="Wide Marker", xlabel="Bucket", ylabel="Signal");
bottom = panel!(fig, 2, 1; title="Wide Labels", xlabel="Category", ylabel="Score");

line!(top, 1:5, [0.3, 0.7, 0.5, 0.9, 0.8]; color=:cyan, marker='🐱');

bar!(
    bottom,
    ["界", "海", "山", "空"],
    [0.72, 0.58, 0.81, 0.66];
    color=:yellow,
    width=0.78,
);

ylims!(bottom, 0, 1);
```

```julia
using TermPlot

fig = Figure(GridLayout(2, 1); title="Wide Unicode Support", width=112, height=24, legend=false)

top = panel!(fig, 1, 1; title="Wide Marker", xlabel="Bucket", ylabel="Signal")
bottom = panel!(fig, 2, 1; title="Wide Labels", xlabel="Category", ylabel="Score")

line!(top, 1:5, [0.3, 0.7, 0.5, 0.9, 0.8]; color=:cyan, marker='🐱')

bar!(
    bottom,
    ["界", "海", "山", "空"],
    [0.72, 0.58, 0.81, 0.66];
    color=:yellow,
    width=0.78,
)

ylims!(bottom, 0, 1)

display(fig)
```

```@example labels_legends_unicode; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```
