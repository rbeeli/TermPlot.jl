# Stacked Bars

Stacked bars are useful for compositions and grouped categorical breakdowns.

```julia
using TermPlot

fig = Figure(title="Stacked Bar Example")
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

Typical uses:

- portfolio composition snapshots
- categorical decomposition
- sampled allocation history
