# Basic Line Plots

Basic line plots are the default starting point for `TermPlot.jl`.

The chart below is generated during the docs build.

```@ansi basic_line_plots
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

# Emit the actual terminal output into the docs.
withenv("NO_COLOR" => nothing) do
    render!(IOContext(stdout, :color => true), fig)
    println()
end
```

This works well for:

- normalized price series
- strategy versus benchmark charts
- indicator overlays on one axis
