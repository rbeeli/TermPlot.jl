# Layouts

`TermPlot.jl` layouts are driven by `GridLayout(rows, cols; rowweights, colweights, rowgap, colgap)`.
Panels can occupy a single cell or span across multiple rows and columns.

The charts below are generated during the docs build.

## Uniform Grid

```@setup layouts_uniform
using Dates
using TermPlot

fig = Figure(GridLayout(2, 2); title="Uniform Grid", width=112, height=28, linkx=true);

strategy = panel!(fig, 1, 1; title="Strategy", xlabel="Date", ylabel="Equity", x_date_format=dateformat"mm-dd");
benchmark = panel!(fig, 1, 2; title="Benchmark", xlabel="Date", ylabel="Equity", x_date_format=dateformat"mm-dd");
spread = panel!(fig, 2, 1; title="Spread", xlabel="Date", ylabel="bps", x_date_format=dateformat"mm-dd");
signal = panel!(fig, 2, 2; title="Signal", xlabel="Date", ylabel="Score", x_date_format=dateformat"mm-dd");

x = [Date(2024, 5, 1) + Day(i) for i in 0:9];

line!(strategy, x, [100, 101, 103, 102, 105, 107, 106, 109, 111, 112]; label="Strategy", color=:cyan);
line!(benchmark, x, [100, 100, 101, 101, 102, 103, 103, 104, 105, 105]; label="Benchmark", color=:blue);
line!(spread, x, [0, 10, 20, 15, 30, 35, 28, 42, 50, 55]; label="Spread", color=:yellow);
scatter!(signal, x, [-0.3, -0.1, 0.2, 0.4, 0.1, 0.5, 0.3, 0.7, 0.6, 0.8]; label="Signal", color=:magenta, marker="diamond");
hline!(signal, 0.0; label="Zero", color=:gray);
```

```julia
using Dates
using TermPlot

fig = Figure(GridLayout(2, 2); title="Uniform Grid", width=112, height=28, linkx=true)

strategy = panel!(fig, 1, 1; title="Strategy", xlabel="Date", ylabel="Equity", x_date_format=dateformat"mm-dd")
benchmark = panel!(fig, 1, 2; title="Benchmark", xlabel="Date", ylabel="Equity", x_date_format=dateformat"mm-dd")
spread = panel!(fig, 2, 1; title="Spread", xlabel="Date", ylabel="bps", x_date_format=dateformat"mm-dd")
signal = panel!(fig, 2, 2; title="Signal", xlabel="Date", ylabel="Score", x_date_format=dateformat"mm-dd")

x = [Date(2024, 5, 1) + Day(i) for i in 0:9]

line!(strategy, x, [100, 101, 103, 102, 105, 107, 106, 109, 111, 112]; label="Strategy", color=:cyan)
line!(benchmark, x, [100, 100, 101, 101, 102, 103, 103, 104, 105, 105]; label="Benchmark", color=:blue)
line!(spread, x, [0, 10, 20, 15, 30, 35, 28, 42, 50, 55]; label="Spread", color=:yellow)
scatter!(signal, x, [-0.3, -0.1, 0.2, 0.4, 0.1, 0.5, 0.3, 0.7, 0.6, 0.8]; label="Signal", color=:magenta, marker="diamond")
hline!(signal, 0.0; label="Zero", color=:gray)

display(fig)
```

```@example layouts_uniform; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Weighted Columns

Use `colweights` and `rowweights` when some panels deserve more room than others.

```@setup layouts_weighted
using Dates
using TermPlot

fig = Figure(GridLayout(1, 3; colweights=[2.4, 1.0, 1.0], colgap=2); title="Weighted Columns", width=112, height=22, legend=false);

main = panel!(fig, 1, 1; title="Main Track", xlabel="Date", ylabel="Level", x_date_format=dateformat"mm-dd");
drawdown = panel!(fig, 1, 2; title="Drawdown", xlabel="Date", ylabel="%", x_date_format=dateformat"mm-dd");
hits = panel!(fig, 1, 3; title="Hits", xlabel="Date", ylabel="Count", x_date_format=dateformat"mm-dd");

x = [Date(2024, 3, 1) + Day(i) for i in 0:8];

line!(main, x, [1.00, 1.01, 1.04, 1.03, 1.06, 1.08, 1.07, 1.10, 1.13]; color=:cyan);
line!(drawdown, x, [0.0, -0.3, -0.1, -0.5, -0.2, -0.1, -0.4, -0.2, 0.0]; color=:yellow);
bar!(hits, x, [2, 1, 4, 3, 5, 2, 6, 4, 5]; color=:magenta, width=0.82);
```

```julia
using Dates
using TermPlot

fig = Figure(GridLayout(1, 3; colweights=[2.4, 1.0, 1.0], colgap=2); title="Weighted Columns", width=112, height=22, legend=false)

main = panel!(fig, 1, 1; title="Main Track", xlabel="Date", ylabel="Level", x_date_format=dateformat"mm-dd")
drawdown = panel!(fig, 1, 2; title="Drawdown", xlabel="Date", ylabel="%", x_date_format=dateformat"mm-dd")
hits = panel!(fig, 1, 3; title="Hits", xlabel="Date", ylabel="Count", x_date_format=dateformat"mm-dd")

x = [Date(2024, 3, 1) + Day(i) for i in 0:8]

line!(main, x, [1.00, 1.01, 1.04, 1.03, 1.06, 1.08, 1.07, 1.10, 1.13]; color=:cyan)
line!(drawdown, x, [0.0, -0.3, -0.1, -0.5, -0.2, -0.1, -0.4, -0.2, 0.0]; color=:yellow)
bar!(hits, x, [2, 1, 4, 3, 5, 2, 6, 4, 5]; color=:magenta, width=0.82)

display(fig)
```

```@example layouts_weighted; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Row And Column Spans

Panels can span ranges of rows or columns to build dashboard-style arrangements.

```@setup layouts_spans
using Dates
using TermPlot

fig = Figure(
    GridLayout(3, 3; rowweights=[2.0, 2.0, 1.2], colweights=[2.2, 1.2, 1.2], rowgap=1, colgap=2);
    title="Spanning Layout",
    width=112,
    height=30,
    linkx=true,
    legend=false,
);

main = panel!(fig, 1:2, 1:2; title="Main Equity", xlabel="Date", ylabel="Normalized", x_date_format=dateformat"mm-dd");
risk = panel!(fig, 1, 3; title="Risk", xlabel="Date", ylabel="Vol", x_date_format=dateformat"mm-dd");
trades = panel!(fig, 2, 3; title="Trades", xlabel="Date", ylabel="Count", x_date_format=dateformat"mm-dd");
signal = panel!(fig, 3, 1:3; title="Composite Signal", xlabel="Date", ylabel="Score", x_date_format=dateformat"mm-dd");

x = [Date(2024, 8, 1) + Day(i) for i in 0:9];

line!(main, x, [1.00, 1.02, 1.05, 1.03, 1.08, 1.10, 1.09, 1.12, 1.15, 1.18]; color=:cyan);
line!(risk, x, [0.22, 0.24, 0.26, 0.25, 0.29, 0.31, 0.28, 0.30, 0.27, 0.25]; color=:yellow);
bar!(trades, x, [3, 2, 5, 4, 6, 5, 7, 4, 6, 5]; color=:magenta, width=0.82);
line!(signal, x, [-0.4, -0.1, 0.2, 0.5, 0.1, 0.6, 0.3, 0.7, 0.5, 0.8]; color=:blue, marker=:diamond);
hline!(signal, 0.0; color=:gray);
```

```julia
using Dates
using TermPlot

fig = Figure(
    GridLayout(3, 3; rowweights=[2.0, 2.0, 1.2], colweights=[2.2, 1.2, 1.2], rowgap=1, colgap=2);
    title="Spanning Layout",
    width=112,
    height=30,
    linkx=true,
    legend=false,
)

main = panel!(fig, 1:2, 1:2; title="Main Equity", xlabel="Date", ylabel="Normalized", x_date_format=dateformat"mm-dd")
risk = panel!(fig, 1, 3; title="Risk", xlabel="Date", ylabel="Vol", x_date_format=dateformat"mm-dd")
trades = panel!(fig, 2, 3; title="Trades", xlabel="Date", ylabel="Count", x_date_format=dateformat"mm-dd")
signal = panel!(fig, 3, 1:3; title="Composite Signal", xlabel="Date", ylabel="Score", x_date_format=dateformat"mm-dd")

x = [Date(2024, 8, 1) + Day(i) for i in 0:9]

line!(main, x, [1.00, 1.02, 1.05, 1.03, 1.08, 1.10, 1.09, 1.12, 1.15, 1.18]; color=:cyan)
line!(risk, x, [0.22, 0.24, 0.26, 0.25, 0.29, 0.31, 0.28, 0.30, 0.27, 0.25]; color=:yellow)
bar!(trades, x, [3, 2, 5, 4, 6, 5, 7, 4, 6, 5]; color=:magenta, width=0.82)
line!(signal, x, [-0.4, -0.1, 0.2, 0.5, 0.1, 0.6, 0.3, 0.7, 0.5, 0.8]; color=:blue, marker=:diamond)
hline!(signal, 0.0; color=:gray)

display(fig)
```

```@example layouts_spans; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```
