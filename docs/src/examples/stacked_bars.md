# Stacked Bars

Stacked bars are useful for compositions and grouped categorical breakdowns.

The chart below is generated during the docs build.

```@setup stacked_bars
using TermPlot

fig = Figure(title="Stacked Bar Example", width=96, height=22);
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

fig = Figure(title="Stacked Bar Example", width=96, height=22)
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

```@setup stacked_bars_time
using Dates
using TermPlot

fig = Figure(title="Time-Based Stacked Bars", width=108, height=24);
panel!(
    fig;
    title="Portfolio Allocation Over Time",
    xlabel="Week",
    ylabel="Weight %",
    x_date_format=dateformat"yyyy-mm-dd",
);

x = [Date(2024, 1, 5) + Week(i) for i in 0:7];

stackedbar!(
    fig,
    x,
    [0.28, 0.26, 0.24, 0.22, 0.20, 0.18, 0.17, 0.16],
    [0.22, 0.24, 0.23, 0.21, 0.19, 0.18, 0.17, 0.16],
    [0.18, 0.17, 0.19, 0.20, 0.18, 0.17, 0.16, 0.15],
    [0.16, 0.15, 0.14, 0.16, 0.18, 0.20, 0.21, 0.22],
    [0.16, 0.18, 0.20, 0.21, 0.25, 0.27, 0.29, 0.31];
    labels=["Equities", "Bonds", "Gold", "Commodities", "Cash"],
    colors=[:cyan, :blue, :yellow, :magenta, :green],
    width=1.0,
);

ylims!(fig, 0, 1);
```

```julia
using Dates
using TermPlot

fig = Figure(title="Time-Based Stacked Bars", width=108, height=24)
panel!(
    fig;
    title="Portfolio Allocation Over Time",
    xlabel="Week",
    ylabel="Weight %",
    x_date_format=dateformat"yyyy-mm-dd",
)

x = [Date(2024, 1, 5) + Week(i) for i in 0:7]

stackedbar!(
    fig,
    x,
    [0.28, 0.26, 0.24, 0.22, 0.20, 0.18, 0.17, 0.16],
    [0.22, 0.24, 0.23, 0.21, 0.19, 0.18, 0.17, 0.16],
    [0.18, 0.17, 0.19, 0.20, 0.18, 0.17, 0.16, 0.15],
    [0.16, 0.15, 0.14, 0.16, 0.18, 0.20, 0.21, 0.22],
    [0.16, 0.18, 0.20, 0.21, 0.25, 0.27, 0.29, 0.31];
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
