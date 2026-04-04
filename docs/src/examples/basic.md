# Line Charts

Line charts are the default starting point for `TermPlot.jl`.

The chart below is generated during the docs build.

```@setup basic_line_plots
using Dates
using TermPlot

fig = Figure(title="Basic Example", width=96, height=22);
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

fig = Figure(title="Basic Example", width=96, height=22)
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
