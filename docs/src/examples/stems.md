# Stem Plots

Stem plots are useful when each observation should remain visually tied to a reference level.
They work well for impulses, event magnitudes, and bucketed factor scores.

```@setup stem_plots
using TermPlot

fig = Figure(title="Stem Example", width=96, height=22);
panel!(fig; title="Event Magnitudes", xlabel="Bucket", ylabel="Signal");

stem!(
    fig,
    1:8,
    [0.15, 0.55, -0.25, 0.82, -0.10, 0.42, 0.70, -0.18];
    label="Events",
    color=:cyan,
    marker=:diamond,
);

hline!(fig, 0.0; color=:gray, label="Baseline");
```

```julia
using TermPlot

fig = Figure(title="Stem Example", width=96, height=22)
panel!(fig; title="Event Magnitudes", xlabel="Bucket", ylabel="Signal")

stem!(
    fig,
    1:8,
    [0.15, 0.55, -0.25, 0.82, -0.10, 0.42, 0.70, -0.18];
    label="Events",
    color=:cyan,
    marker=:diamond,
)

hline!(fig, 0.0; color=:gray, label="Baseline")

display(fig)
```

```@example stem_plots; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Custom Baselines

The default baseline is `0.0`, but you can shift it with `baseline=...`.
That is useful for spreads, centered oscillators, or targets relative to a threshold.

```@setup shifted_stems
using TermPlot

fig = Figure(title="Shifted Baseline", width=96, height=22);
panel!(fig; title="Spread Around Carry Hurdle", xlabel="Tenor", ylabel="Spread");

stem!(
    fig,
    ["1M", "3M", "6M", "9M", "12M"],
    [12.0, 18.0, 11.0, 24.0, 16.0];
    label="Observed",
    color=:yellow,
    baseline=15.0,
    marker='●',
);

hline!(fig, 15.0; color=:gray, label="Hurdle");
ylims!(fig, 8.0, 26.0);
```

```julia
using TermPlot

fig = Figure(title="Shifted Baseline", width=96, height=22)
panel!(fig; title="Spread Around Carry Hurdle", xlabel="Tenor", ylabel="Spread")

stem!(
    fig,
    ["1M", "3M", "6M", "9M", "12M"],
    [12.0, 18.0, 11.0, 24.0, 16.0];
    label="Observed",
    color=:yellow,
    baseline=15.0,
    marker='●',
)

hline!(fig, 15.0; color=:gray, label="Hurdle")
ylims!(fig, 8.0, 26.0)

display(fig)
```

```@example shifted_stems; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```
