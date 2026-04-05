# Layouts

`GridLayout` controls panel geometry through:

- track weights with `rowweights` and `colweights`
- explicit seams with `rowseams` and `colseams`
- seam styles `:separate` and `:adjacent`
- optional plot-area alignment groups with `rowaligns` and `colaligns`
- panel spans via `panel!(fig, rows, cols; ...)`

Each seam is a `GridSeam`. `GridSeam(:separate; gap=2)` keeps a visible gap, while `GridSeam(:adjacent)` packs the neighboring panels together and shares the seam.

## Align Plot Areas

Use `rowaligns` and `colaligns` when you want plot rectangles to line up even if panels have different titles, labels, or tick widths. `:all` aligns every track on that axis, while vectors like `[:pair, :pair, :none]` align only selected rows or columns together.

```@setup layouts_aligned
using TermPlot

fig = Figure(
    GridLayout(1, 3; colseams=GridSeam(; gap=2), rowaligns=:all, colaligns=[:pair, :pair, :none]);
    title="Selective Plot Alignment",
    width=112,
    height=16,
    legend=false,
);

left = panel!(fig, 1, 1; title="Titled", xlabel="Bucket", ylabel="Wide Label");
middle = panel!(fig, 1, 2; xlabel="Bucket", ylabel="y");
right = panel!(fig, 1, 3; xlabel="Bucket", ylabel="y");

line!(left, 1:4, [1.0, 2.0, 1.5, 3.0]; color=:cyan);
line!(middle, 1:4, [0.1, 0.2, 0.15, 0.25]; color=:yellow);
line!(right, 1:4, [100000.0, 120000.0, 90000.0, 110000.0]; color=:magenta);
```

```julia
using TermPlot

fig = Figure(
    GridLayout(1, 3; colseams=GridSeam(; gap=2), rowaligns=:all, colaligns=[:pair, :pair, :none]);
    title="Selective Plot Alignment",
    width=112,
    height=16,
    legend=false,
)

left = panel!(fig, 1, 1; title="Titled", xlabel="Bucket", ylabel="Wide Label")
middle = panel!(fig, 1, 2; xlabel="Bucket", ylabel="y")
right = panel!(fig, 1, 3; xlabel="Bucket", ylabel="y")

line!(left, 1:4, [1.0, 2.0, 1.5, 3.0]; color=:cyan)
line!(middle, 1:4, [0.1, 0.2, 0.15, 0.25]; color=:yellow)
line!(right, 1:4, [100000.0, 120000.0, 90000.0, 110000.0]; color=:magenta)

display(fig)
```

```@example layouts_aligned; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Separated Grid

```@setup layouts_separated
using Dates
using TermPlot

fig = Figure(
    GridLayout(2, 2; rowseams=GridSeam(; gap=1), colseams=GridSeam(; gap=3), rowaligns=:all, colaligns=:all);
    title="Separated Grid",
    width=112,
    height=28,
    linkx=true,
);

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

fig = Figure(
    GridLayout(2, 2; rowseams=GridSeam(; gap=1), colseams=GridSeam(; gap=3), rowaligns=:all, colaligns=:all);
    title="Separated Grid",
    width=112,
    height=28,
    linkx=true,
)

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

```@example layouts_separated; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Adjacent Columns

An adjacent column seam packs the panels together and shares the vertical seam between them.
Add `rowaligns=:all` so panels in the row reserve the same header and x-axis budget.

```@setup layouts_adjacent_cols
using Dates
using TermPlot

fig = Figure(
    GridLayout(1, 2; rowaligns=:all, colseams=GridSeam(:adjacent), colaligns=:all);
    title="Adjacent Columns",
    width=108,
    height=20,
    linkx=true,
    linky=true,
    legend=false,
);

left = panel!(fig, 1, 1; title="Strategy A", xlabel="Date", ylabel="Normalized", x_date_format=dateformat"mm-dd");
right = panel!(fig, 1, 2; title="Strategy B", xlabel="Date", ylabel="Normalized", x_date_format=dateformat"mm-dd");

x1 = [Date(2024, 7, 1) + Day(i) for i in 0:7];
x2 = [Date(2024, 7, 2) + Day(i) for i in 0:7];

line!(left, x1, [1.00, 1.02, 1.05, 1.03, 1.07, 1.09, 1.08, 1.11]; color=:cyan);
line!(right, x2, [0.97, 1.00, 1.01, 1.04, 1.02, 1.05, 1.07, 1.10]; color=:magenta);
```

```julia
using Dates
using TermPlot

fig = Figure(
    GridLayout(1, 2; rowaligns=:all, colseams=GridSeam(:adjacent), colaligns=:all);
    title="Adjacent Columns",
    width=108,
    height=20,
    linkx=true,
    linky=true,
    legend=false,
)

left = panel!(fig, 1, 1; title="Strategy A", xlabel="Date", ylabel="Normalized", x_date_format=dateformat"mm-dd")
right = panel!(fig, 1, 2; title="Strategy B", xlabel="Date", ylabel="Normalized", x_date_format=dateformat"mm-dd")

x1 = [Date(2024, 7, 1) + Day(i) for i in 0:7]
x2 = [Date(2024, 7, 2) + Day(i) for i in 0:7]

line!(left, x1, [1.00, 1.02, 1.05, 1.03, 1.07, 1.09, 1.08, 1.11]; color=:cyan)
line!(right, x2, [0.97, 1.00, 1.01, 1.04, 1.02, 1.05, 1.07, 1.10]; color=:magenta)

display(fig)
```

```@example layouts_adjacent_cols; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Adjacent Rows

An adjacent row seam removes the vertical gap and keeps only the outer x-axis visible. Omitting the lower panel header text keeps the shared seam visually flush.

```@setup layouts_adjacent_rows
using TermPlot

fig = Figure(
    GridLayout(2, 1; rowseams=GridSeam(:adjacent), rowaligns=:all);
    title="Adjacent Rows",
    width=96,
    height=24,
    linkx=true,
    legend=false,
);

top = panel!(fig, 1, 1; title="Exposure", xlabel="Bucket", ylabel="Gross");
bottom = panel!(fig, 2, 1; xlabel="Bucket");

x = 1:8;

line!(top, x, [0.5, 0.7, 0.8, 0.6, 0.9, 1.0, 0.95, 1.1]; color=:yellow, marker=:circle);
line!(bottom, x, [-0.4, -0.1, 0.2, 0.5, 0.1, 0.6, 0.3, 0.7]; color=:cyan, marker=:diamond);
hline!(bottom, 0.0; color=:gray);
```

```julia
using TermPlot

fig = Figure(
    GridLayout(2, 1; rowseams=GridSeam(:adjacent), rowaligns=:all);
    title="Adjacent Rows",
    width=96,
    height=24,
    linkx=true,
    legend=false,
)

top = panel!(fig, 1, 1; title="Exposure", xlabel="Bucket", ylabel="Gross")
bottom = panel!(fig, 2, 1; xlabel="Bucket")

x = 1:8

line!(top, x, [0.5, 0.7, 0.8, 0.6, 0.9, 1.0, 0.95, 1.1]; color=:yellow, marker=:circle)
line!(bottom, x, [-0.4, -0.1, 0.2, 0.5, 0.1, 0.6, 0.3, 0.7]; color=:cyan, marker=:diamond)
hline!(bottom, 0.0; color=:gray)

display(fig)
```

```@example layouts_adjacent_rows; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Mixed Seams, Weights, And Spans

You can mix adjacent and separated seams in one layout while still using weighted tracks and panel spans.

```@setup layouts_mixed
using Dates
using TermPlot

fig = Figure(
    GridLayout(
        2,
        3;
        rowweights=[2.0, 1.2],
        colweights=[2.2, 1.2, 1.2],
        rowseams=GridSeam(; gap=1),
        colseams=[GridSeam(:adjacent), GridSeam(; gap=2)],
        rowaligns=:all,
        colaligns=[:main, :main, :side],
    );
    title="Mixed Seams",
    width=112,
    height=26,
    linkx=true,
    legend=false,
);

main = panel!(fig, 1, 1:2; title="Main Track", xlabel="Date", ylabel="Normalized", x_date_format=dateformat"mm-dd");
risk = panel!(fig, 1, 3; title="Risk", xlabel="Date", ylabel="Vol", x_date_format=dateformat"mm-dd");
spread = panel!(fig, 2, 1:2; title="Spread", xlabel="Date", ylabel="bps", x_date_format=dateformat"mm-dd");
hits = panel!(fig, 2, 3; title="Hits", xlabel="Date", ylabel="Count", x_date_format=dateformat"mm-dd");

x = [Date(2024, 8, 1) + Day(i) for i in 0:9];

line!(main, x, [1.00, 1.02, 1.05, 1.03, 1.08, 1.10, 1.09, 1.12, 1.15, 1.18]; color=:cyan);
line!(risk, x, [0.22, 0.24, 0.26, 0.25, 0.29, 0.31, 0.28, 0.30, 0.27, 0.25]; color=:yellow);
line!(spread, x, [0, 8, 16, 12, 24, 30, 27, 35, 43, 48]; color=:blue);
bar!(hits, x, [3, 2, 5, 4, 6, 5, 7, 4, 6, 5]; color=:magenta, width=0.82);
```

```julia
using Dates
using TermPlot

fig = Figure(
    GridLayout(
        2,
        3;
        rowweights=[2.0, 1.2],
        colweights=[2.2, 1.2, 1.2],
        rowseams=GridSeam(; gap=1),
        colseams=[GridSeam(:adjacent), GridSeam(; gap=2)],
        rowaligns=:all,
        colaligns=[:main, :main, :side],
    );
    title="Mixed Seams",
    width=112,
    height=26,
    linkx=true,
    legend=false,
)

main = panel!(fig, 1, 1:2; title="Main Track", xlabel="Date", ylabel="Normalized", x_date_format=dateformat"mm-dd")
risk = panel!(fig, 1, 3; title="Risk", xlabel="Date", ylabel="Vol", x_date_format=dateformat"mm-dd")
spread = panel!(fig, 2, 1:2; title="Spread", xlabel="Date", ylabel="bps", x_date_format=dateformat"mm-dd")
hits = panel!(fig, 2, 3; title="Hits", xlabel="Date", ylabel="Count", x_date_format=dateformat"mm-dd")

x = [Date(2024, 8, 1) + Day(i) for i in 0:9]

line!(main, x, [1.00, 1.02, 1.05, 1.03, 1.08, 1.10, 1.09, 1.12, 1.15, 1.18]; color=:cyan)
line!(risk, x, [0.22, 0.24, 0.26, 0.25, 0.29, 0.31, 0.28, 0.30, 0.27, 0.25]; color=:yellow)
line!(spread, x, [0, 8, 16, 12, 24, 30, 27, 35, 43, 48]; color=:blue)
bar!(hits, x, [3, 2, 5, 4, 6, 5, 7, 4, 6, 5]; color=:magenta, width=0.82)

display(fig)
```

```@example layouts_mixed; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Asymmetric Dashboard

This kind of layout is useful when you want a main time-series strip, a secondary strip underneath it, and a narrow side sleeve for categorical state or risk information. It combines spans, weighted tracks, adjacent seams, and one separated sleeve.

```@setup layouts_dashboard
using Dates
using TermPlot

fig = Figure(
    GridLayout(
        3,
        4;
        rowweights=[2.2, 1.2, 1.0],
        colweights=[2.3, 1.3, 1.0, 1.2],
        rowseams=[GridSeam(:adjacent), GridSeam(; gap=1)],
        colseams=[GridSeam(:adjacent), GridSeam(:adjacent), GridSeam(; gap=2)],
        rowaligns=:all,
        colaligns=[:core, :core, :core, :side],
    );
    title="Asymmetric Dashboard",
    width=112,
    height=30,
    legend=false,
);

trend = panel!(fig, 1, 1:3; title="Composite Trend", xlabel="Date", ylabel="Level", x_date_format=dateformat"mm-dd");
pullback = panel!(fig, 2, 1:2; title="Pullback", xlabel="Date", ylabel="z-score", x_date_format=dateformat"mm-dd");
carry = panel!(fig, 2, 3; title="Carry", xlabel="Date", ylabel="bps", x_date_format=dateformat"mm-dd");
breadth = panel!(fig, 3, 1:3; title="Breadth", xlabel="Date", ylabel="Share", x_date_format=dateformat"mm-dd");
risk = panel!(fig, 1:3, 4; title="Risk Sleeve", xlabel="Bucket", ylabel="Weight");

x = [Date(2024, 9, 1) + Day(i) for i in 0:11];

line!(trend, x, [100.0, 101.5, 103.0, 102.4, 104.2, 105.6, 106.1, 107.8, 108.5, 109.1, 110.3, 111.0]; color=:cyan);
line!(pullback, x, [-1.0, -0.6, -0.2, 0.4, 0.8, 0.3, -0.1, -0.5, -0.2, 0.5, 0.9, 0.6]; color=:yellow);
hline!(pullback, 0.0; color=:gray);
line!(carry, x, [8.0, 10.0, 11.0, 9.0, 13.0, 14.0, 12.0, 15.0, 16.0, 14.0, 18.0, 19.0]; color=:magenta);
bar!(breadth, x, [0.42, 0.48, 0.55, 0.51, 0.63, 0.68, 0.66, 0.72, 0.75, 0.71, 0.79, 0.82]; color=:green, width=0.84);
stackedbar!(
    risk,
    ["EQ", "Rates", "FX", "Cmdty"],
    [55.0, 20.0, 15.0, 10.0],
    [25.0, 30.0, 35.0, 30.0],
    [20.0, 50.0, 50.0, 60.0];
    labels=["Trend", "Carry", "Defensive"],
    colors=[:cyan, :yellow, :blue],
    width=0.82,
);
ylims!(risk, 0, 100);
```

```julia
using Dates
using TermPlot

fig = Figure(
    GridLayout(
        3,
        4;
        rowweights=[2.2, 1.2, 1.0],
        colweights=[2.3, 1.3, 1.0, 1.2],
        rowseams=[GridSeam(:adjacent), GridSeam(; gap=1)],
        colseams=[GridSeam(:adjacent), GridSeam(:adjacent), GridSeam(; gap=2)],
        rowaligns=:all,
        colaligns=[:core, :core, :core, :side],
    );
    title="Asymmetric Dashboard",
    width=112,
    height=30,
    legend=false,
)

trend = panel!(fig, 1, 1:3; title="Composite Trend", xlabel="Date", ylabel="Level", x_date_format=dateformat"mm-dd")
pullback = panel!(fig, 2, 1:2; title="Pullback", xlabel="Date", ylabel="z-score", x_date_format=dateformat"mm-dd")
carry = panel!(fig, 2, 3; title="Carry", xlabel="Date", ylabel="bps", x_date_format=dateformat"mm-dd")
breadth = panel!(fig, 3, 1:3; title="Breadth", xlabel="Date", ylabel="Share", x_date_format=dateformat"mm-dd")
risk = panel!(fig, 1:3, 4; title="Risk Sleeve", xlabel="Bucket", ylabel="Weight")

x = [Date(2024, 9, 1) + Day(i) for i in 0:11]

line!(trend, x, [100.0, 101.5, 103.0, 102.4, 104.2, 105.6, 106.1, 107.8, 108.5, 109.1, 110.3, 111.0]; color=:cyan)
line!(pullback, x, [-1.0, -0.6, -0.2, 0.4, 0.8, 0.3, -0.1, -0.5, -0.2, 0.5, 0.9, 0.6]; color=:yellow)
hline!(pullback, 0.0; color=:gray)
line!(carry, x, [8.0, 10.0, 11.0, 9.0, 13.0, 14.0, 12.0, 15.0, 16.0, 14.0, 18.0, 19.0]; color=:magenta)
bar!(breadth, x, [0.42, 0.48, 0.55, 0.51, 0.63, 0.68, 0.66, 0.72, 0.75, 0.71, 0.79, 0.82]; color=:green, width=0.84)
stackedbar!(
    risk,
    ["EQ", "Rates", "FX", "Cmdty"],
    [55.0, 20.0, 15.0, 10.0],
    [25.0, 30.0, 35.0, 30.0],
    [20.0, 50.0, 50.0, 60.0];
    labels=["Trend", "Carry", "Defensive"],
    colors=[:cyan, :yellow, :blue],
    width=0.82,
)
ylims!(risk, 0, 100)

display(fig)
```

```@example layouts_dashboard; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Adjacent Core With Spanning Detail Panels

You can also keep a dense core of adjacent panels and then break away to a separate footer track. This is useful for small multiples with one shared state ladder and one full-width summary panel.

```@setup layouts_core
using TermPlot

fig = Figure(
    GridLayout(
        3,
        3;
        rowweights=[1.2, 1.2, 0.9],
        colweights=[1.4, 1.4, 1.0],
        rowseams=[GridSeam(:adjacent), GridSeam(; gap=2)],
        colseams=[GridSeam(:adjacent), GridSeam(; gap=2)],
        rowaligns=[:core, :core, :footer],
        colaligns=[:core, :core, :detail],
    );
    title="Adjacent Core",
    width=112,
    height=28,
    legend=false,
);

lead = panel!(fig, 1, 1; title="Lead", xlabel="Bucket", ylabel="Signal");
follow = panel!(fig, 1, 2; title="Follow", xlabel="Bucket", ylabel="Signal");
states = panel!(fig, 1:2, 3; title="State Ladder", xlabel="Bucket", ylabel="Rank");
breadth = panel!(fig, 2, 1; xlabel="Bucket", ylabel="Spread");
turnover = panel!(fig, 2, 2; xlabel="Bucket");
footer = panel!(fig, 3, 1:3; title="Execution Footprint", xlabel="Bucket", ylabel="Count");

x = 1:8;

line!(lead, x, [0.2, 0.4, 0.7, 0.5, 0.8, 0.9, 0.85, 1.0]; color=:cyan, marker=:circle);
line!(follow, x, [0.1, 0.3, 0.6, 0.45, 0.65, 0.8, 0.75, 0.92]; color=:yellow, marker=:diamond);
line!(breadth, x, [-0.4, -0.1, 0.2, 0.5, 0.1, 0.6, 0.3, 0.7]; color=:magenta);
hline!(breadth, 0.0; color=:gray);
bar!(turnover, x, [18, 15, 21, 19, 24, 22, 26, 23]; color=:green, width=0.82);
stackedbar!(
    states,
    ["S1", "S2", "S3", "S4"],
    [35.0, 20.0, 10.0, 25.0],
    [45.0, 55.0, 60.0, 40.0],
    [20.0, 25.0, 30.0, 35.0];
    labels=["Trend", "Neutral", "Stress"],
    colors=[:cyan, :yellow, :red],
    width=0.82,
);
ylims!(states, 0, 100);
bar!(footer, x, [6, 8, 5, 9, 7, 10, 8, 11]; color=:blue, width=0.82);
```

```julia
using TermPlot

fig = Figure(
    GridLayout(
        3,
        3;
        rowweights=[1.2, 1.2, 0.9],
        colweights=[1.4, 1.4, 1.0],
        rowseams=[GridSeam(:adjacent), GridSeam(; gap=2)],
        colseams=[GridSeam(:adjacent), GridSeam(; gap=2)],
        rowaligns=[:core, :core, :footer],
        colaligns=[:core, :core, :detail],
    );
    title="Adjacent Core",
    width=112,
    height=28,
    legend=false,
)

lead = panel!(fig, 1, 1; title="Lead", xlabel="Bucket", ylabel="Signal")
follow = panel!(fig, 1, 2; title="Follow", xlabel="Bucket", ylabel="Signal")
states = panel!(fig, 1:2, 3; title="State Ladder", xlabel="Bucket", ylabel="Rank")
breadth = panel!(fig, 2, 1; xlabel="Bucket", ylabel="Spread")
turnover = panel!(fig, 2, 2; xlabel="Bucket")
footer = panel!(fig, 3, 1:3; title="Execution Footprint", xlabel="Bucket", ylabel="Count")

x = 1:8

line!(lead, x, [0.2, 0.4, 0.7, 0.5, 0.8, 0.9, 0.85, 1.0]; color=:cyan, marker=:circle)
line!(follow, x, [0.1, 0.3, 0.6, 0.45, 0.65, 0.8, 0.75, 0.92]; color=:yellow, marker=:diamond)
line!(breadth, x, [-0.4, -0.1, 0.2, 0.5, 0.1, 0.6, 0.3, 0.7]; color=:magenta)
hline!(breadth, 0.0; color=:gray)
bar!(turnover, x, [18, 15, 21, 19, 24, 22, 26, 23]; color=:green, width=0.82)
stackedbar!(
    states,
    ["S1", "S2", "S3", "S4"],
    [35.0, 20.0, 10.0, 25.0],
    [45.0, 55.0, 60.0, 40.0],
    [20.0, 25.0, 30.0, 35.0];
    labels=["Trend", "Neutral", "Stress"],
    colors=[:cyan, :yellow, :red],
    width=0.82,
)
ylims!(states, 0, 100)
bar!(footer, x, [6, 8, 5, 9, 7, 10, 8, 11]; color=:blue, width=0.82)

display(fig)
```

```@example layouts_core; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```
