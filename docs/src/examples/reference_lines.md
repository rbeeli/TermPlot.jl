# Reference Lines

Reference lines are useful for thresholds, event markers, and regime boundaries.

The chart below is generated during the docs build.

```@setup reference_lines
using Dates
using TermPlot

fig = Figure(title="Reference Lines Example", width=96, height=22);
panel!(fig; title="Breakout Monitor", xlabel="Date", ylabel="Close", x_date_format=dateformat"yyyy-mm-dd");

x = [Date(2024, 1, 1) + Day(i) for i in 0:11];
close = [101, 102, 103, 104, 103, 105, 107, 106, 108, 110, 109, 111];

line!(fig, x, close; label="Close", color=:cyan);
hline!(fig, 105.0; label="Trigger", color=:yellow);
vline!(fig, Date(2024, 1, 7); label="Entry", color=:magenta);
vline!(fig, Date(2024, 1, 10); label="Retest", color=:red);

ylims!(fig, 100, 112);
```

```julia
using Dates
using TermPlot

fig = Figure(title="Reference Lines Example", width=96, height=22)
panel!(fig; title="Breakout Monitor", xlabel="Date", ylabel="Close", x_date_format=dateformat"yyyy-mm-dd")

x = [Date(2024, 1, 1) + Day(i) for i in 0:11]
close = [101, 102, 103, 104, 103, 105, 107, 106, 108, 110, 109, 111]

line!(fig, x, close; label="Close", color=:cyan)
hline!(fig, 105.0; label="Trigger", color=:yellow)
vline!(fig, Date(2024, 1, 7); label="Entry", color=:magenta)
vline!(fig, Date(2024, 1, 10); label="Retest", color=:red)

ylims!(fig, 100, 112)

display(fig)
```

```@example reference_lines; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```
