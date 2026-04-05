# Axes

This page focuses on axis behavior: dual y-axes, datetime formatting, manual limits, tick density, and log scaling.

The charts below are generated during the docs build.

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

## Datetime Formatting, Limits, and Log Scale

```@setup axes_controls
using Dates
using TermPlot

fig = Figure(title="Axis Controls Example", width=96, height=22);
panel!(
    fig;
    title="Date Formatting and Log Scale",
    xlabel="Date",
    ylabel="Equity",
    x_date_format=dateformat"mm-dd",
    xfrequency=4,
    yfrequency=5,
    yscale=:log10,
);

x = [Date(2024, 4, 1) + Day(i) for i in 0:11];
equity = [100, 112, 128, 121, 149, 182, 230, 215, 305, 380, 465, 560];

line!(fig, x, equity; label="Equity", color=:magenta);
hline!(fig, 100; label="Start", color=:gray);

xlims!(fig, x[2], x[end - 1]);
ylims!(fig, 90, 650);
```

```julia
using Dates
using TermPlot

fig = Figure(title="Axis Controls Example", width=96, height=22)
panel!(
    fig;
    title="Date Formatting and Log Scale",
    xlabel="Date",
    ylabel="Equity",
    x_date_format=dateformat"mm-dd",
    xfrequency=4,
    yfrequency=5,
    yscale=:log10,
)

x = [Date(2024, 4, 1) + Day(i) for i in 0:11]
equity = [100, 112, 128, 121, 149, 182, 230, 215, 305, 380, 465, 560]

line!(fig, x, equity; label="Equity", color=:magenta)
hline!(fig, 100; label="Start", color=:gray)

xlims!(fig, x[2], x[end - 1])
ylims!(fig, 90, 650)

display(fig)
```

```@example axes_controls; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```
