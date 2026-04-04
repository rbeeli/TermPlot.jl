# Linked Layouts

Linked layouts are useful when multiple panels should stay visually aligned.

The chart below is generated during the docs build.

```@setup linked_layouts
using Dates
using TermPlot

fig = Figure(; title="Linked Layout Example", width=120, height=24, layout=(1, 2), linkx=true, linky=true);

panel!(fig, 1, 1; title="Strategy A", xlabel="Date", ylabel="Normalized");
panel!(fig, 1, 2; title="Strategy B", xlabel="Date", ylabel="Normalized");

x1 = [Date(2024, 1, 1) + Day(i) for i in 0:7];
x2 = [Date(2024, 1, 2) + Day(i) for i in 0:7];

line!(fig.panels[1, 1], x1, [1.0, 1.01, 1.03, 1.02, 1.05, 1.07, 1.06, 1.08]; label="A", color=:cyan);
line!(fig.panels[1, 2], x2, [0.98, 1.00, 1.01, 1.04, 1.03, 1.05, 1.07, 1.09]; label="B", color=:magenta);

```

```julia
using Dates
using TermPlot

fig = Figure(; title="Linked Layout Example", width=120, height=24, layout=(1, 2), linkx=true, linky=true)

panel!(fig, 1, 1; title="Strategy A", xlabel="Date", ylabel="Normalized")
panel!(fig, 1, 2; title="Strategy B", xlabel="Date", ylabel="Normalized")

x1 = [Date(2024, 1, 1) + Day(i) for i in 0:7]
x2 = [Date(2024, 1, 2) + Day(i) for i in 0:7]

line!(fig.panels[1, 1], x1, [1.0, 1.01, 1.03, 1.02, 1.05, 1.07, 1.06, 1.08]; label="A", color=:cyan)
line!(fig.panels[1, 2], x2, [0.98, 1.00, 1.01, 1.04, 1.03, 1.05, 1.07, 1.09]; label="B", color=:magenta)

display(fig)
```

```@example linked_layouts; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```
