# Rendering Output

`TermPlot.jl` has two output paths:

- terminal text via `render`, `render!`, `show(fig)`, `display(fig)`, and `show(::MIME"text/plain", ...)`
- SVG via `render_svg`, `render_svg!`, and explicit `show(::MIME"image/svg+xml", ...)`

Both renderers share the same plot layout and rasterization, so the SVG output
tracks the terminal output closely.

## Plain-Text Rendering

```@setup rendering_plain
using Dates
using TermPlot

fig = Figure(title="Plain Text Render", width=112, height=24)
panel!(
    fig;
    title="Strategy",
    xlabel="Date",
    ylabel="Normalized",
    x_date_format=dateformat"mm-dd",
)

x = [Date(2024, 1, 1) + Day(i) for i in 0:7]
line!(fig, x, [1.0, 1.03, 1.05, 1.01, 1.08, 1.12, 1.10, 1.15]; label="Strategy", color=:cyan)
hline!(fig, 1.0; label="Baseline", color=:gray)
```

```julia
text = render(fig)
print(text)
```

```@example rendering_plain; ansicolor=true
withenv("NO_COLOR" => nothing) do # hide
    render!(IOContext(stdout, :color => true), fig) # hide
    println() # hide
end # hide
nothing # hide
```

## Writing To An IO

Use `render!` when you want to stream into a file, buffer, socket, or custom
display sink.

```julia
open("chart.txt", "w") do io
    render!(io, fig)
end

buffer = IOBuffer()
render!(buffer, fig)
text = String(take!(buffer))
```

## Color Control With IOContext

The plain-text renderer respects `IOContext(io, :color => ...)`.

```julia
plain = IOBuffer()
render!(IOContext(plain, :color => false), fig)

ansi = IOBuffer()
render!(IOContext(ansi, :color => true), fig)
```

Use `:color => false` when you need plain logs or deterministic snapshots. Use
`:color => true` when the destination understands ANSI escape sequences.
Explicit `:color` takes precedence over `NO_COLOR`.

## Display Integration

These calls all use the plain-text renderer:

```julia
show(fig)
display(fig)
show(stdout, MIME"text/plain"(), fig)
```

`TermPlot.jl` does not advertise SVG as an automatic display preference.
That keeps `display(fig)` on the terminal-text path even in rich frontends.

SVG output is available only when you request it explicitly:

```julia
show(stdout, MIME"image/svg+xml"(), fig)
```

## SVG Rendering

```julia
svg = render_svg(fig)

open("chart.svg", "w") do io
    render_svg!(io, fig)
end
```

The SVG renderer preserves box drawing, braille rasterization, ANSI-derived
colors, and bold styling. It defaults to a monospace stack starting with
`JuliaMono` on a dark `#161618` background.

See [SVG Export](examples/svg.md) for a dedicated preview page.
