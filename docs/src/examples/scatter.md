# Scatter Plots

Scatter plots are useful for discrete observations, trade markers, and parameter sweeps.

The chart below is generated during the docs build.

```@setup scatter_plots
using TermPlot

fig = Figure(title="Scatter Example", width=96, height=22);
panel!(fig; title="Parameter Sweep", xlabel="Configuration", ylabel="Risk-adjusted return");

scatter!(
    fig,
    1:6,
    [0.25, 0.48, 0.61, 0.72, 0.68, 0.64];
    label="Momentum",
    color=:cyan,
    marker="diamond",
);

scatter!(
    fig,
    1:6,
    [0.10, 0.22, 0.35, 0.42, 0.55, 0.53];
    label="Carry",
    color=:yellow,
    marker="square",
);

scatter!(
    fig,
    1:6,
    [-0.05, 0.08, 0.18, 0.28, 0.36, 0.40];
    label="Mean Reversion",
    color=:magenta,
    marker="circle",
);

hline!(fig, 0.0; color=:gray, label="Zero");
ylims!(fig, -0.1, 0.8);
```

```julia
using TermPlot

fig = Figure(title="Scatter Example", width=96, height=22)
panel!(fig; title="Parameter Sweep", xlabel="Configuration", ylabel="Risk-adjusted return")

scatter!(
    fig,
    1:6,
    [0.25, 0.48, 0.61, 0.72, 0.68, 0.64];
    label="Momentum",
    color=:cyan,
    marker="diamond",
)

scatter!(
    fig,
    1:6,
    [0.10, 0.22, 0.35, 0.42, 0.55, 0.53];
    label="Carry",
    color=:yellow,
    marker="square",
)

scatter!(
    fig,
    1:6,
    [-0.05, 0.08, 0.18, 0.28, 0.36, 0.40];
    label="Mean Reversion",
    color=:magenta,
    marker="circle",
)

hline!(fig, 0.0; color=:gray, label="Zero")
ylims!(fig, -0.1, 0.8)

display(fig)
```

```@example scatter_plots; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```
