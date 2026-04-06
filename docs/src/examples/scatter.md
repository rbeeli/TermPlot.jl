# Scatter Plots

Scatter plots are useful for discrete observations, trade markers, and parameter sweeps.

The chart below is generated during the docs build.

```@setup scatter_plots
using TermPlot

fig = Figure(title="Scatter Example", width=112, height=24);
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

fig = Figure(title="Scatter Example", width=112, height=24)
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

## Linear Fit Overlay

Scatter plots also work well for visualizing a simple fitted trend line. The
example below computes an ordinary least-squares line directly from the points,
then overlays the fit on top of the observations.

```@setup scatter_regression
using TermPlot

function fit_line(x, y)
    x_mean, y_mean = sum(x) / length(x), sum(y) / length(y)
    slope = sum((xi - x_mean) * (yi - y_mean) for (xi, yi) in zip(x, y)) / sum((xi - x_mean)^2 for xi in x)
    intercept = y_mean - slope * x_mean
    slope, intercept
end

# generate ellipse-like point cloud
u = ((1:400) .- 0.5) ./ 400; θ = 2π .* mod.((1:400) .* ((√5 - 1) / 2), 1)
z1, z2 = sqrt.(-2 .* log.(u)) .* cos.(θ), sqrt.(-2 .* log.(u)) .* sin.(θ)
x, y = 1.0 .* z1 .+ 0.1 .* z2, 1.3 .* z1 .+ 1.2 .* z2

# compute fit line
slope, intercept = fit_line(x, y)
x_fit = [minimum(x), maximum(x)]
y_fit = [intercept + slope * xi for xi in x_fit]

fit = Figure(title="Scatter With Fitted Line", width=112, height=48)
panel!(fit; title="Linear Regression", xlabel="Feature value", ylabel="Target")

scatter!(fit, x, y; label="Observations", color=:yellow, marker="diamond")
line!(fit, x_fit, y_fit; label="Least-squares fit", color=:red)
```

```julia
using TermPlot

function fit_line(x, y)
    x_mean, y_mean = sum(x) / length(x), sum(y) / length(y)
    slope = sum((xi - x_mean) * (yi - y_mean) for (xi, yi) in zip(x, y)) / sum((xi - x_mean)^2 for xi in x)
    intercept = y_mean - slope * x_mean
    slope, intercept
end

# generate ellipse-like point cloud
u = ((1:400) .- 0.5) ./ 400; θ = 2π .* mod.((1:400) .* ((√5 - 1) / 2), 1)
z1, z2 = sqrt.(-2 .* log.(u)) .* cos.(θ), sqrt.(-2 .* log.(u)) .* sin.(θ)
x, y = 1.0 .* z1 .+ 0.1 .* z2, 1.3 .* z1 .+ 1.2 .* z2

# compute fit line
slope, intercept = fit_line(x, y)
x_fit = [minimum(x), maximum(x)]
y_fit = [intercept + slope * xi for xi in x_fit]

fit = Figure(title="Scatter With Fitted Line", width=112, height=48)
panel!(fit; title="Linear Regression", xlabel="Feature value", ylabel="Target")

scatter!(fit, x, y; label="Observations", color=:yellow, marker="diamond")
line!(fit, x_fit, y_fit; label="Least-squares fit", color=:red)

display(fit)
```

```@example scatter_regression; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fit) # hide
    println() # hide
end # hide
nothing # hide
```
