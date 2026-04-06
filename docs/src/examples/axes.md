# Axes

This page walks through axis features progressively, from the default numeric
axes to labels, dates, date-times, dual axes, log scaling, and linked axes
across panels.

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

## DateTime Axes

```@setup axes_datetime
using Dates
using TermPlot

fig = Figure(title="DateTime Axis Example", width=100, height=20);
panel!(
    fig;
    title="Intraday Signal",
    xlabel="Time",
    ylabel="Score",
    x_date_format=dateformat"mm-dd HH:MM",
    xfrequency=5,
);

x = [DateTime(2024, 4, 1, 9, 30) + Hour(i) for i in 0:7];
signal = [0.15, 0.22, 0.35, 0.28, 0.42, 0.55, 0.49, 0.61];
checks = [0.12, 0.21, 0.32, 0.31, 0.39, 0.52, 0.50, 0.58];

line!(fig, x, signal; label="Signal", color=:cyan, marker=:circle);
scatter!(fig, x, checks; label="Checks", color=:yellow, marker=:diamond);

ylims!(fig, 0.0, 0.7);
```

```julia
using Dates
using TermPlot

fig = Figure(title="DateTime Axis Example", width=100, height=20)
panel!(
    fig;
    title="Intraday Signal",
    xlabel="Time",
    ylabel="Score",
    x_date_format=dateformat"mm-dd HH:MM",
    xfrequency=5,
)

x = [DateTime(2024, 4, 1, 9, 30) + Hour(i) for i in 0:7]
signal = [0.15, 0.22, 0.35, 0.28, 0.42, 0.55, 0.49, 0.61]
checks = [0.12, 0.21, 0.32, 0.31, 0.39, 0.52, 0.50, 0.58]

line!(fig, x, signal; label="Signal", color=:cyan, marker=:circle)
scatter!(fig, x, checks; label="Checks", color=:yellow, marker=:diamond)

ylims!(fig, 0.0, 0.7)

display(fig)
```

```@example axes_datetime; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Zoned DateTime Axes

```@setup axes_zoned
using Dates
using TimeZones
using TermPlot

fig = Figure(title="Zoned Time Axis Example", width=104, height=20);
panel!(
    fig;
    title="New York Session",
    xlabel="Time",
    ylabel="Level",
    x_date_format=dateformat"mm-dd HH:MM",
    xfrequency=4,
);

x = [
    ZonedDateTime(2024, 1, 2, 9, 30, 0, tz"America/New_York"),
    ZonedDateTime(2024, 1, 2, 11, 0, 0, tz"America/New_York"),
    ZonedDateTime(2024, 1, 2, 12, 30, 0, tz"America/New_York"),
    ZonedDateTime(2024, 1, 2, 14, 0, 0, tz"America/New_York"),
    ZonedDateTime(2024, 1, 2, 16, 0, 0, tz"America/New_York"),
];
levels = [100.0, 101.5, 101.0, 102.8, 103.6];

line!(fig, x, levels; label="Session", color=:magenta, marker=:circle);
ylims!(fig, 99.0, 104.5);
```

```julia
using Dates
using TimeZones
using TermPlot

fig = Figure(title="Zoned Time Axis Example", width=104, height=20)
panel!(
    fig;
    title="New York Session",
    xlabel="Time",
    ylabel="Level",
    x_date_format=dateformat"mm-dd HH:MM",
    xfrequency=4,
)

x = [
    ZonedDateTime(2024, 1, 2, 9, 30, 0, tz"America/New_York"),
    ZonedDateTime(2024, 1, 2, 11, 0, 0, tz"America/New_York"),
    ZonedDateTime(2024, 1, 2, 12, 30, 0, tz"America/New_York"),
    ZonedDateTime(2024, 1, 2, 14, 0, 0, tz"America/New_York"),
    ZonedDateTime(2024, 1, 2, 16, 0, 0, tz"America/New_York"),
]
levels = [100.0, 101.5, 101.0, 102.8, 103.6]

line!(fig, x, levels; label="Session", color=:magenta, marker=:circle)
ylims!(fig, 99.0, 104.5)

display(fig)
```

```@example axes_zoned; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

!!! note "Time Axis Rules"
    - `Date` axes default to `yyyy-mm-dd` formatting.
    - `DateTime` axes default to `yyyy-mm-dd HH:MM` formatting.
    - Mixed `Date` and `DateTime` inputs on one x-axis are promoted to a `DateTime` axis.
    - `ZonedDateTime` tick labels are formatted in the timezone inferred from the first zoned x value on that axis.

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

`log10` y-axes require positive visible limits and positive plotted values on
that y-side.

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

!!! note "Linked Axis Rules And Caveats"
    - `linkx=true` shares one x context and one x range across all panels.
    - Linked categorical x-axes merge categories across panels before limits are computed.
    - `linky=true` links the left and right y-sides separately.
    - Only panels with real data on a y-side, or explicit limits on that side, participate in that shared y range.
    - Linked y-axes on the same side must use identical scales. Mixing `:linear` and `:log10` on one linked side raises an error.
