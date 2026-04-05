# Axes

This page walks through axis features progressively, from the default numeric axes to labels, dates, dual axes, log scaling, and linked axes across panels.

The charts below are generated during the docs build.

## Simple Numeric Axes

```@setup axes_numeric
using TermPlot

fig = Figure(title="Numeric Axes Example", width=88, height=18);
panel!(fig);

line!(fig, 1:8, [0.2, 0.5, 0.9, 0.7, 1.1, 1.4, 1.3, 1.6]; color=:cyan);
```

```julia
using TermPlot

fig = Figure(title="Numeric Axes Example", width=88, height=18)
panel!(fig)

line!(fig, 1:8, [0.2, 0.5, 0.9, 0.7, 1.1, 1.4, 1.3, 1.6]; color=:cyan)

display(fig)
```

```@example axes_numeric; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Labels, Limits, and Tick Density

`xfrequency` and `yfrequency` set the target tick density for each axis. They are approximate counts, not strict guarantees: `TermPlot` still snaps ticks to readable positions and may thin labels to avoid overlap.

```@setup axes_labeled
using TermPlot

fig = Figure(title="Axis Labels Example", width=92, height=20);
panel!(
    fig;
    title="Labeled Numeric Axes",
    xlabel="Step",
    ylabel="Signal",
    xfrequency=5,
    yfrequency=4,
);

x = 0:9;
y = [-0.2, 0.1, 0.4, 0.8, 0.6, 0.9, 1.3, 1.1, 1.5, 1.7];

line!(fig, x, y; label="Signal", color=:magenta);
hline!(fig, 0.0; label="Zero", color=:gray);

xlims!(fig, 1, 8);
ylims!(fig, -0.4, 1.8);
```

```julia
using TermPlot

fig = Figure(title="Axis Labels Example", width=92, height=20)
panel!(
    fig;
    title="Labeled Numeric Axes",
    xlabel="Step",
    ylabel="Signal",
    xfrequency=5,
    yfrequency=4,
)

x = 0:9
y = [-0.2, 0.1, 0.4, 0.8, 0.6, 0.9, 1.3, 1.1, 1.5, 1.7]

line!(fig, x, y; label="Signal", color=:magenta)
hline!(fig, 0.0; label="Zero", color=:gray)

xlims!(fig, 1, 8)
ylims!(fig, -0.4, 1.8)

display(fig)
```

```@example axes_labeled; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Date Axes

```@setup axes_dates
using Dates
using TermPlot

fig = Figure(title="Date Axis Example", width=96, height=20);
panel!(
    fig;
    title="Date Formatting",
    xlabel="Date",
    ylabel="Equity",
    x_date_format=dateformat"mm-dd",
    xfrequency=4,
);

x = [Date(2024, 4, 1) + Day(i) for i in 0:11];
equity = [100, 104, 109, 106, 112, 118, 121, 119, 126, 130, 128, 134];

line!(fig, x, equity; label="Equity", color=:cyan);

xlims!(fig, x[2], x[end - 1]);
ylims!(fig, 98, 136);
```

```julia
using Dates
using TermPlot

fig = Figure(title="Date Axis Example", width=96, height=20)
panel!(
    fig;
    title="Date Formatting",
    xlabel="Date",
    ylabel="Equity",
    x_date_format=dateformat"mm-dd",
    xfrequency=4,
)

x = [Date(2024, 4, 1) + Day(i) for i in 0:11]
equity = [100, 104, 109, 106, 112, 118, 121, 119, 126, 130, 128, 134]

line!(fig, x, equity; label="Equity", color=:cyan)

xlims!(fig, x[2], x[end - 1])
ylims!(fig, 98, 136)

display(fig)
```

```@example axes_dates; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Dual Y-Axis

```@setup axes_dual
using Dates
using TermPlot

fig = Figure(title="Dual Axis Example", width=96, height=22);
panel!(
    fig;
    title="Equity and Drawdown",
    xlabel="Date",
    ylabel="Equity",
    ylabel_right="Drawdown %",
    x_date_format=dateformat"yyyy-mm-dd",
);

x = [Date(2024, 1, 1) + Day(i) for i in 0:14];
equity = [100, 101, 102, 99, 104, 107, 108, 110, 109, 111, 112, 115, 117, 116, 119];
drawdown = [0, -1, -0.5, -3, -1, 0, -0.2, 0, -0.8, -0.1, 0, 0, 0, -0.5, 0];

line!(fig, x, equity; label="Equity", color=:cyan);
line!(fig, x, drawdown; label="Drawdown", color=:red, yside=:right);

ylims!(fig, minimum(equity) - 2, maximum(equity) + 2);
ylims!(fig, -5, 1; yside=:right);
hline!(fig, 0; color=:gray, yside=:right);
```

```julia
using Dates
using TermPlot

fig = Figure(title="Dual Axis Example", width=96, height=22)
panel!(
    fig;
    title="Equity and Drawdown",
    xlabel="Date",
    ylabel="Equity",
    ylabel_right="Drawdown %",
    x_date_format=dateformat"yyyy-mm-dd",
)

x = [Date(2024, 1, 1) + Day(i) for i in 0:14]
equity = [100, 101, 102, 99, 104, 107, 108, 110, 109, 111, 112, 115, 117, 116, 119]
drawdown = [0, -1, -0.5, -3, -1, 0, -0.2, 0, -0.8, -0.1, 0, 0, 0, -0.5, 0]

line!(fig, x, equity; label="Equity", color=:cyan)
line!(fig, x, drawdown; label="Drawdown", color=:red, yside=:right)

ylims!(fig, minimum(equity) - 2, maximum(equity) + 2)
ylims!(fig, -5, 1; yside=:right)
hline!(fig, 0; color=:gray, yside=:right)

display(fig)
```

```@example axes_dual; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Log Scale

```@setup axes_log
using Dates
using TermPlot

fig = Figure(title="Log Scale Example", width=96, height=22);
panel!(
    fig;
    title="Log10 Y-Axis",
    xlabel="Date",
    ylabel="Equity",
    x_date_format=dateformat"mm-dd",
    yscale=:log10,
    yfrequency=5,
);

x = [Date(2024, 6, 1) + Day(i) for i in 0:9];
equity = [100, 115, 140, 180, 220, 290, 360, 430, 520, 650];

line!(fig, x, equity; label="Equity", color=:yellow);
hline!(fig, 100; label="Start", color=:gray);

ylims!(fig, 90, 700);
```

```julia
using Dates
using TermPlot

fig = Figure(title="Log Scale Example", width=96, height=22)
panel!(
    fig;
    title="Log10 Y-Axis",
    xlabel="Date",
    ylabel="Equity",
    x_date_format=dateformat"mm-dd",
    yscale=:log10,
    yfrequency=5,
)

x = [Date(2024, 6, 1) + Day(i) for i in 0:9]
equity = [100, 115, 140, 180, 220, 290, 360, 430, 520, 650]

line!(fig, x, equity; label="Equity", color=:yellow)
hline!(fig, 100; label="Start", color=:gray)

ylims!(fig, 90, 700)

display(fig)
```

```@example axes_log; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Linked Axes Across Panels

```@setup axes_linked
using Dates
using TermPlot

fig = Figure(GridLayout(1, 2); title="Linked Axes Example", width=108, height=24, linkx=true, linky=true);

left = panel!(fig, 1, 1; title="Strategy A", xlabel="Date", ylabel="Normalized", x_date_format=dateformat"mm-dd");
right = panel!(fig, 1, 2; title="Strategy B", xlabel="Date", ylabel="Normalized", x_date_format=dateformat"mm-dd");

x1 = [Date(2024, 7, 1) + Day(i) for i in 0:7];
x2 = [Date(2024, 7, 2) + Day(i) for i in 0:7];

line!(left, x1, [1.00, 1.02, 1.05, 1.03, 1.07, 1.09, 1.08, 1.11]; label="A", color=:cyan);
line!(right, x2, [0.97, 1.00, 1.01, 1.04, 1.02, 1.05, 1.07, 1.10]; label="B", color=:magenta);
```

```julia
using Dates
using TermPlot

fig = Figure(GridLayout(1, 2); title="Linked Axes Example", width=108, height=24, linkx=true, linky=true)

left = panel!(fig, 1, 1; title="Strategy A", xlabel="Date", ylabel="Normalized", x_date_format=dateformat"mm-dd")
right = panel!(fig, 1, 2; title="Strategy B", xlabel="Date", ylabel="Normalized", x_date_format=dateformat"mm-dd")

x1 = [Date(2024, 7, 1) + Day(i) for i in 0:7]
x2 = [Date(2024, 7, 2) + Day(i) for i in 0:7]

line!(left, x1, [1.00, 1.02, 1.05, 1.03, 1.07, 1.09, 1.08, 1.11]; label="A", color=:cyan)
line!(right, x2, [0.97, 1.00, 1.01, 1.04, 1.02, 1.05, 1.07, 1.10]; label="B", color=:magenta)

display(fig)
```

```@example axes_linked; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```
