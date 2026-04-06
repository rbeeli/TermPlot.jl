# Stacked Bars

Stacked bars are useful for compositions and grouped categorical breakdowns.
When ANSI color is unavailable, each stack layer falls back to a distinct fill
texture so the composition stays readable in plain text.

The chart below is generated during the docs build.

```@setup stacked_bars
using TermPlot

fig = Figure(title="Stacked Bar Example", width=112, height=22);
panel!(fig; title="Allocation Mix", xlabel="Bucket", ylabel="Weight %");

stackedbar!(
    fig,
    ["A", "B", "C", "D"],
    [35.0, 20.0, 25.0, 30.0],
    [45.0, 55.0, 50.0, 40.0],
    [20.0, 25.0, 25.0, 30.0];
    labels=["Risky", "Defensive", "Cash"],
    colors=[:cyan, :yellow, :green],
    width=0.8,
);

ylims!(fig, 0, 100);

```

```julia
using TermPlot

fig = Figure(title="Stacked Bar Example", width=112, height=22)
panel!(fig; title="Allocation Mix", xlabel="Bucket", ylabel="Weight %")

stackedbar!(
    fig,
    ["A", "B", "C", "D"],
    [35.0, 20.0, 25.0, 30.0],
    [45.0, 55.0, 50.0, 40.0],
    [20.0, 25.0, 25.0, 30.0];
    labels=["Risky", "Defensive", "Cash"],
    colors=[:cyan, :yellow, :green],
    width=0.8,
)

ylims!(fig, 0, 100)

display(fig)
```

```@example stacked_bars; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Time-Based Allocation

This variant uses a `Date` x-axis and `width=1.0` so consecutive time buckets touch with no gap.
The allocation rotates across risk-on, defensive, and inflation-sensitive sleeves instead of drifting one-way.

```@setup stacked_bars_time
using Dates
using TermPlot

fig = Figure(title="Time-Based Stacked Bars", width=112, height=24);
panel!(
    fig;
    title="Portfolio Allocation Over Time",
    xlabel="Week",
    ylabel="Weight %",
    x_date_format=dateformat"yyyy-mm-dd",
);

x = [Date(2024, 1, 5) + Week(i) for i in 0:11];

allocations = [
    0.32 0.20 0.08 0.18 0.22;
    0.28 0.24 0.10 0.20 0.18;
    0.22 0.30 0.12 0.18 0.18;
    0.18 0.34 0.14 0.12 0.22;
    0.16 0.32 0.18 0.10 0.24;
    0.20 0.26 0.16 0.16 0.22;
    0.27 0.22 0.12 0.22 0.17;
    0.31 0.18 0.10 0.24 0.17;
    0.26 0.20 0.09 0.27 0.18;
    0.22 0.24 0.11 0.22 0.21;
    0.19 0.29 0.13 0.16 0.23;
    0.24 0.23 0.15 0.14 0.24;
];

equities = allocations[:, 1];
bonds = allocations[:, 2];
gold = allocations[:, 3];
commodities = allocations[:, 4];
cash = allocations[:, 5];

stackedbar!(
    fig,
    x,
    equities,
    bonds,
    gold,
    commodities,
    cash;
    labels=["Equities", "Bonds", "Gold", "Commodities", "Cash"],
    colors=[:cyan, :blue, :yellow, :magenta, :green],
    width=1.0,
);

ylims!(fig, 0, 1);
```

```julia
using Dates
using TermPlot

fig = Figure(title="Time-Based Stacked Bars", width=112, height=24)
panel!(
    fig;
    title="Portfolio Allocation Over Time",
    xlabel="Week",
    ylabel="Weight %",
    x_date_format=dateformat"yyyy-mm-dd",
)

x = [Date(2024, 1, 5) + Week(i) for i in 0:11]

allocations = [
    0.32 0.20 0.08 0.18 0.22;
    0.28 0.24 0.10 0.20 0.18;
    0.22 0.30 0.12 0.18 0.18;
    0.18 0.34 0.14 0.12 0.22;
    0.16 0.32 0.18 0.10 0.24;
    0.20 0.26 0.16 0.16 0.22;
    0.27 0.22 0.12 0.22 0.17;
    0.31 0.18 0.10 0.24 0.17;
    0.26 0.20 0.09 0.27 0.18;
    0.22 0.24 0.11 0.22 0.21;
    0.19 0.29 0.13 0.16 0.23;
    0.24 0.23 0.15 0.14 0.24;
]

equities = allocations[:, 1]
bonds = allocations[:, 2]
gold = allocations[:, 3]
commodities = allocations[:, 4]
cash = allocations[:, 5]

stackedbar!(
    fig,
    x,
    equities,
    bonds,
    gold,
    commodities,
    cash;
    labels=["Equities", "Bonds", "Gold", "Commodities", "Cash"],
    colors=[:cyan, :blue, :yellow, :magenta, :green],
    width=1.0,
)

ylims!(fig, 0, 1)

display(fig)
```

```@example stacked_bars_time; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Monochrome Textures

The same time-based allocation figure rendered with `:color => false` falls
back to per-layer textures and plain legend markers. That keeps the stacked
composition readable in logs and snapshots without ANSI support.

```julia
render!(IOContext(stdout, :color => false), fig)
```

```@example stacked_bars_time
render!(IOContext(stdout, :color => false), fig) # hide
println() # hide
nothing # hide
```
