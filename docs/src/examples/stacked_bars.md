# Stacked Bars

Stacked bars are useful for compositions and grouped categorical breakdowns.

The chart below is generated during the docs build.

```@ansi stacked_bars
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

withenv("NO_COLOR" => nothing) do
    render!(IOContext(stdout, :color => true), fig)
    println()
end
```

Typical uses:

- portfolio composition snapshots
- categorical decomposition
- sampled allocation history
