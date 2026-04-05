# Layouts

This page focuses on multi-panel figure layouts, from a simple linked comparison to a denser 2x2 monitoring grid.

The charts below are generated during the docs build.

## Linked 1x2 Comparison

```@setup layouts_linked
using Dates
using TermPlot

fig = Figure(; title="Linked Layout Example", width=120, height=24, layout=(1, 2), linkx=true, linky=true);

panel!(fig, 1, 1; title="Strategy A", xlabel="Date", ylabel="Normalized", x_date_format=dateformat"yyyy-mm-dd");
panel!(fig, 1, 2; title="Strategy B", xlabel="Date", ylabel="Normalized", x_date_format=dateformat"yyyy-mm-dd");

x1 = [Date(2024, 1, 1) + Day(i) for i in 0:7];
x2 = [Date(2024, 1, 2) + Day(i) for i in 0:7];

line!(fig.panels[1, 1], x1, [1.0, 1.01, 1.03, 1.02, 1.05, 1.07, 1.06, 1.08]; label="A", color=:cyan);
line!(fig.panels[1, 2], x2, [0.98, 1.00, 1.01, 1.04, 1.03, 1.05, 1.07, 1.09]; label="B", color=:magenta);
```

```julia
using Dates
using TermPlot

fig = Figure(; title="Linked Layout Example", width=120, height=24, layout=(1, 2), linkx=true, linky=true)

panel!(fig, 1, 1; title="Strategy A", xlabel="Date", ylabel="Normalized", x_date_format=dateformat"yyyy-mm-dd")
panel!(fig, 1, 2; title="Strategy B", xlabel="Date", ylabel="Normalized", x_date_format=dateformat"yyyy-mm-dd")

x1 = [Date(2024, 1, 1) + Day(i) for i in 0:7]
x2 = [Date(2024, 1, 2) + Day(i) for i in 0:7]

line!(fig.panels[1, 1], x1, [1.0, 1.01, 1.03, 1.02, 1.05, 1.07, 1.06, 1.08]; label="A", color=:cyan)
line!(fig.panels[1, 2], x2, [0.98, 1.00, 1.01, 1.04, 1.03, 1.05, 1.07, 1.09]; label="B", color=:magenta)

display(fig)
```

```@example layouts_linked; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## 2x2 Monitoring Grid

```@setup layouts_grid
using Dates
using TermPlot

fig = Figure(; title="2x2 Layout Example", width=124, height=30, layout=(2, 2), linkx=true);

panel!(fig, 1, 1; title="Strategy", xlabel="Date", ylabel="Equity", x_date_format=dateformat"mm-dd");
panel!(fig, 1, 2; title="Benchmark", xlabel="Date", ylabel="Equity", x_date_format=dateformat"mm-dd");
panel!(fig, 2, 1; title="Spread", xlabel="Date", ylabel="bps", x_date_format=dateformat"mm-dd");
panel!(fig, 2, 2; title="Signal", xlabel="Date", ylabel="Score", x_date_format=dateformat"mm-dd");

x = [Date(2024, 5, 1) + Day(i) for i in 0:9];
strategy = [100, 101, 103, 102, 105, 107, 106, 109, 111, 112];
benchmark = [100, 100, 101, 101, 102, 103, 103, 104, 105, 105];
spread = [0, 10, 20, 15, 30, 35, 28, 42, 50, 55];
signal = [-0.3, -0.1, 0.2, 0.4, 0.1, 0.5, 0.3, 0.7, 0.6, 0.8];

line!(fig.panels[1, 1], x, strategy; label="Strategy", color=:cyan);
line!(fig.panels[1, 2], x, benchmark; label="Benchmark", color=:blue);
line!(fig.panels[2, 1], x, spread; label="Spread", color=:yellow);
scatter!(fig.panels[2, 2], x, signal; label="Signal", color=:magenta, marker="diamond");
hline!(fig.panels[2, 2], 0.0; label="Zero", color=:gray);
```

```julia
using Dates
using TermPlot

fig = Figure(; title="2x2 Layout Example", width=124, height=30, layout=(2, 2), linkx=true)

panel!(fig, 1, 1; title="Strategy", xlabel="Date", ylabel="Equity", x_date_format=dateformat"mm-dd")
panel!(fig, 1, 2; title="Benchmark", xlabel="Date", ylabel="Equity", x_date_format=dateformat"mm-dd")
panel!(fig, 2, 1; title="Spread", xlabel="Date", ylabel="bps", x_date_format=dateformat"mm-dd")
panel!(fig, 2, 2; title="Signal", xlabel="Date", ylabel="Score", x_date_format=dateformat"mm-dd")

x = [Date(2024, 5, 1) + Day(i) for i in 0:9]
strategy = [100, 101, 103, 102, 105, 107, 106, 109, 111, 112]
benchmark = [100, 100, 101, 101, 102, 103, 103, 104, 105, 105]
spread = [0, 10, 20, 15, 30, 35, 28, 42, 50, 55]
signal = [-0.3, -0.1, 0.2, 0.4, 0.1, 0.5, 0.3, 0.7, 0.6, 0.8]

line!(fig.panels[1, 1], x, strategy; label="Strategy", color=:cyan)
line!(fig.panels[1, 2], x, benchmark; label="Benchmark", color=:blue)
line!(fig.panels[2, 1], x, spread; label="Spread", color=:yellow)
scatter!(fig.panels[2, 2], x, signal; label="Signal", color=:magenta, marker="diamond")
hline!(fig.panels[2, 2], 0.0; label="Zero", color=:gray)

display(fig)
```

```@example layouts_grid; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```
