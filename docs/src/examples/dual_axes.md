# Dual Axes

Use dual axes when two related series share the same x-axis but live on different scales.

```julia
using Dates
using TermPlot

fig = Figure(title="Dual Axis Example")
panel!(
    fig;
    title="Equity and Drawdown",
    xlabel="Date",
    ylabel="Equity",
    ylabel_right="Drawdown %",
    x_date_format=dateformat"yyyy-mm-dd",
)

x = [Date(2024, 1, 1) + Day(i) for i in 0:14]
equity = [100, 101, 102, 99, 104, 107, 108, 110, 109, 111, 112, 115, 117, 116, 119]
drawdown = [0, -1, -0.5, -3, -1, 0, -0.2, 0, -0.8, -0.1, 0, 0, 0, -0.5, 0]

line!(fig, x, equity; label="Equity", color=:cyan)
line!(fig, x, drawdown; label="Drawdown", color=:red, yside=:right)

ylims!(fig, minimum(equity) - 2, maximum(equity) + 2)
ylims!(fig, -5, 1; yside=:right)
hline!(fig, 0; color=:gray, yside=:right)

display(fig)
```

Typical uses:

- equity and drawdown
- price and z-score
- level and percentage utilization
