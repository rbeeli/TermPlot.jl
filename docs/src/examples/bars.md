# Bar Charts

Simple bars are useful for ranked cross-sections, factor snapshots, and discrete volume-style series.

The charts below are generated during the docs build.

## Cross-Section Snapshot

```@setup bars_cross_section
using TermPlot

fig = Figure(title="Bar Chart Example", width=96, height=22);
panel!(fig; title="Factor Snapshot", xlabel="Bucket", ylabel="Score");

bar!(
    fig,
    ["Value", "Quality", "Momentum", "Carry", "Low Vol"],
    [0.82, 0.68, 0.91, 0.57, 0.74];
    label="Composite score",
    color=:cyan,
    width=0.8,
);

ylims!(fig, 0, 1);
```

```julia
using TermPlot

fig = Figure(title="Bar Chart Example", width=96, height=22)
panel!(fig; title="Factor Snapshot", xlabel="Bucket", ylabel="Score")

bar!(
    fig,
    ["Value", "Quality", "Momentum", "Carry", "Low Vol"],
    [0.82, 0.68, 0.91, 0.57, 0.74];
    label="Composite score",
    color=:cyan,
    width=0.8,
)

ylims!(fig, 0, 1)

display(fig)
```

```@example bars_cross_section; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Time-Based Bars

```@setup bars_time
using Dates
using TermPlot

fig = Figure(title="Time Bar Example", width=108, height=24);
panel!(
    fig;
    title="Daily Traded Volume",
    xlabel="Date",
    ylabel="Millions",
    x_date_format=dateformat"yyyy-mm-dd",
);

x = [Date(2024, 2, 1) + Day(i) for i in 0:11];
volume = [14, 18, 21, 17, 24, 28, 19, 23, 31, 27, 22, 26];

bar!(fig, x, volume; label="Volume", color=:blue, width=0.82);
ylims!(fig, 0, 35);
```

```julia
using Dates
using TermPlot

fig = Figure(title="Time Bar Example", width=108, height=24)
panel!(
    fig;
    title="Daily Traded Volume",
    xlabel="Date",
    ylabel="Millions",
    x_date_format=dateformat"yyyy-mm-dd",
)

x = [Date(2024, 2, 1) + Day(i) for i in 0:11]
volume = [14, 18, 21, 17, 24, 28, 19, 23, 31, 27, 22, 26]

bar!(fig, x, volume; label="Volume", color=:blue, width=0.82)
ylims!(fig, 0, 35)

display(fig)
```

```@example bars_time; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```
