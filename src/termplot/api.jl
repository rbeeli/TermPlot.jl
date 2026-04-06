"""
    panel!(fig, row=1, col=1; title="", xlabel="", ylabel="", ylabel_right="", xfrequency=6, yfrequency=6, xscale=:linear, yscale=:linear, y2scale=:linear, x_date_format=nothing)

Create or replace a panel in a figure and make it the current panel.

`row` and `col` can be integers or contiguous ranges, which allows a panel to
span multiple grid cells.

If the placement exactly matches an existing panel, that panel is replaced. A
partially overlapping placement raises an error.

# Keywords

- `title`: panel title
- `xlabel`: bottom x-axis label
- `ylabel`: left y-axis label
- `ylabel_right`: right y-axis label
- `xfrequency`: target x tick density
- `yfrequency`: target y tick density for both y sides
- `xscale`: currently `:linear`
- `yscale`: `:linear` or `:log10` for the left y-axis
- `y2scale`: `:linear` or `:log10` for the right y-axis
- `x_date_format`: optional `DateFormat` for `Date`, `DateTime`, and
  `ZonedDateTime` x-axis ticks
"""
function panel!(
    fig::Figure,
    row::Union{Int,UnitRange{Int}}=1,
    col::Union{Int,UnitRange{Int}}=1;
    title::AbstractString="",
    xlabel::AbstractString="",
    ylabel::AbstractString="",
    ylabel_right::AbstractString="",
    xfrequency::Int=6,
    yfrequency::Int=6,
    xscale::Symbol=:linear,
    yscale::Symbol=:linear,
    y2scale::Symbol=:linear,
    x_date_format::Union{Nothing,DateFormat}=nothing,
)
    rows = _normalize_span(row, fig.layout.rows, :row)
    cols = _normalize_span(col, fig.layout.cols, :col)
    panel = _make_panel(;
        title,
        xlabel,
        ylabel,
        ylabel_right,
        xfrequency,
        yfrequency,
        xscale,
        yscale,
        y2scale,
        x_date_format,
    )
    placement = PanelPlacement(rows, cols, panel)

    exact_ix = findfirst(existing -> existing.rows == rows && existing.cols == cols, fig.placements)
    if !isnothing(exact_ix)
        fig.placements[exact_ix] = placement
    else
        overlap_ix = findfirst(existing -> _placement_overlap(rows, cols, existing.rows, existing.cols), fig.placements)
        if !isnothing(overlap_ix)
            throw(ArgumentError("panel placement rows=$(rows), cols=$(cols) overlaps an existing panel placement"))
        end
        push!(fig.placements, placement)
    end

    fig.current = panel
    panel
end

function Base.push!(panel::Panel, series::AbstractSeries)
    push!(panel.series, series)
    panel
end

Base.push!(fig::Figure, series::AbstractSeries) = push!(currentpanel(fig), series)

function Base.getindex(fig::Figure, row::Int, col::Int)::Panel
    row in 1:fig.layout.rows || throw(BoundsError(1:fig.layout.rows, row))
    col in 1:fig.layout.cols || throw(BoundsError(1:fig.layout.cols, col))
    placement = findfirst(slot -> row in slot.rows && col in slot.cols, fig.placements)
    isnothing(placement) && throw(KeyError((row, col)))
    fig.placements[placement].panel
end

function Base.getindex(fig::Figure, rows::UnitRange{Int}, cols::UnitRange{Int})::Panel
    placement = findfirst(slot -> slot.rows == rows && slot.cols == cols, fig.placements)
    isnothing(placement) && throw(KeyError((rows, cols)))
    fig.placements[placement].panel
end

"""
    line!(target, x, y; kwargs...)

Add a line series to a `Figure` or `Panel`.

When `target` is a `Figure`, the series is added to the current panel.

# Keywords

- `label`: legend label
- `color`: color symbol or string such as `:cyan` or `"cyan"`
- `yside`: `:left`, `:right`, `1`, or `2`
- `step`: `:linear`, `:pre`, `:mid`, or `:post`
- `marker`: `nothing`, a named marker (`"dot"`, `"diamond"`, `"cross"`,
  `"square"`, `"circle"`, `"hd"`), or a single character
"""
function line!(target::Union{Figure,Panel}, x::AbstractVector, y::AbstractVector; kwargs...)
    push!(currentpanel(target), Line(x, y; kwargs...))
end

"""
    stem!(target, x, y; kwargs...)

Add a stem series to a `Figure` or `Panel`.

When `target` is a `Figure`, the series is added to the current panel.

# Keywords

- `label`: legend label
- `color`: color symbol or string such as `:cyan` or `"cyan"`
- `yside`: `:left`, `:right`, `1`, or `2`
- `baseline`: finite numeric stem baseline
- `marker`: `nothing`, a named marker (`"dot"`, `"diamond"`, `"cross"`,
  `"square"`, `"circle"`, `"hd"`), or a single character
"""
function stem!(target::Union{Figure,Panel}, x::AbstractVector, y::AbstractVector; kwargs...)
    push!(currentpanel(target), Stem(x, y; kwargs...))
end

"""
    scatter!(target, x, y; kwargs...)

Add a scatter series to a `Figure` or `Panel`.

When `target` is a `Figure`, the series is added to the current panel.

# Keywords

- `label`: legend label
- `color`: color symbol or string such as `:cyan` or `"cyan"`
- `yside`: `:left`, `:right`, `1`, or `2`
- `marker`: a named marker (`"dot"`, `"diamond"`, `"cross"`, `"square"`,
  `"circle"`, `"hd"`) or a single character
"""
function scatter!(target::Union{Figure,Panel}, x::AbstractVector, y::AbstractVector; kwargs...)
    push!(currentpanel(target), Scatter(x, y; kwargs...))
end

"""
    bar!(target, x, y; kwargs...)

Add a bar series to a `Figure` or `Panel`.

When `target` is a `Figure`, the series is added to the current panel.

# Keywords

- `label`: legend label
- `color`: fill color
- `width`: positive finite bar width in x-axis units
- `yside`: `:left`, `:right`, `1`, or `2`
"""
function bar!(target::Union{Figure,Panel}, x::AbstractVector, y::AbstractVector; kwargs...)
    push!(currentpanel(target), Bar(x, y; kwargs...))
end

"""
    stackedbar!(target, x, ys...; kwargs...)

Add a stacked bar series to a `Figure` or `Panel`.

When `target` is a `Figure`, the series is added to the current panel.

# Keywords

- `labels`: one label per stack component
- `colors`: one color per stack component
- `width`: positive finite bar width in x-axis units
- `yside`: `:left`, `:right`, `1`, or `2`
"""
function stackedbar!(target::Union{Figure,Panel}, x::AbstractVector, ys::AbstractVector...; kwargs...)
    push!(currentpanel(target), Bar(x, ys...; kwargs...))
end

"""
    hline!(target, y; kwargs...)

Add a horizontal reference line to a `Figure` or `Panel`.

When `target` is a `Figure`, the series is added to the current panel.

# Keywords

- `label`: legend label
- `color`: line color
- `yside`: `:left`, `:right`, `1`, or `2`
"""
function hline!(target::Union{Figure,Panel}, y::Real; kwargs...)
    push!(currentpanel(target), HLine(y; kwargs...))
end

"""
    vline!(target, x; kwargs...)

Add a vertical reference line to a `Figure` or `Panel`.

When `target` is a `Figure`, the series is added to the current panel.

# Keywords

- `label`: legend label
- `color`: line color
"""
function vline!(target::Union{Figure,Panel}, x; kwargs...)
    push!(currentpanel(target), VLine(x; kwargs...))
end

"""
    annotate!(target, x, y, text; kwargs...)

Add a text annotation to a `Figure` or `Panel`.

When `target` is a `Figure`, the annotation is added to the current panel.

# Keywords

- `xref`: `:x`, `:paper`, or `:plot`
- `yref`: `:y`, `:y2`, `:paper`, or `:plot`
- `xanchor`: `:left`, `:center`, or `:right`
- `yanchor`: `:top`, `:middle`, `:bottom`, or `:center`
- `align`: `:left`, `:center`, or `:right`
- `xshift`: integer horizontal shift in character cells; positive moves right
- `yshift`: integer vertical shift in character rows; positive moves down
- `color`: annotation text color
"""
function annotate!(target::Union{Figure,Panel}, x, y, text::AbstractString; kwargs...)
    push!(currentpanel(target), Annotation(x, y, text; kwargs...))
end

_validate_axis_limit_value(value::Real, axis_name::AbstractString) = isfinite(Float64(value)) ? value : throw(ArgumentError("$(axis_name) limits must be finite"))
_validate_axis_limit_value(value, ::AbstractString) = value

"""
    xlims!(target, lower, upper)

Set explicit x-axis limits on a `Figure` or `Panel`.

Numeric limits must be finite. Date/time and categorical limits should use the
same value family as the plotted x data.
"""
function xlims!(target::Union{Figure,Panel}, lower, upper)
    panel = currentpanel(target)
    panel.xaxis.limits = (_validate_axis_limit_value(lower, "x-axis"), _validate_axis_limit_value(upper, "x-axis"))
    target
end

"""
    ylims!(target, lower, upper; yside=:left)

Set explicit left or right y-axis limits on a `Figure` or `Panel`.

`yside` must be `:left`, `:right`, `1`, or `2`. Limits must be finite real
values.

# Keywords

- `yside`: `:left`, `:right`, `1`, or `2`
"""
function ylims!(target::Union{Figure,Panel}, lower::Real, upper::Real; yside::Union{Symbol,Integer}=:left)
    axis = yside_symbol(yside) === :right ? currentpanel(target).yaxis_right : currentpanel(target).yaxis_left
    axis.limits = (
        Float64(_validate_axis_limit_value(lower, "y-axis")),
        Float64(_validate_axis_limit_value(upper, "y-axis")),
    )
    target
end

"""
    yscale!(target, scale; yside=:left)

Set the y-axis scale for the left or right side of a `Figure` or `Panel`.

`scale` must be `:linear` or `:log10`. `yside` must be `:left`, `:right`, `1`,
or `2`.

# Keywords

- `yside`: `:left`, `:right`, `1`, or `2`
"""
function yscale!(target::Union{Figure,Panel}, scale::Symbol; yside::Union{Symbol,Integer}=:left)
    _validate_scale(scale, :y)
    axis = yside_symbol(yside) === :right ? currentpanel(target).yaxis_right : currentpanel(target).yaxis_left
    axis.scale = scale
    target
end

"""
    render(fig)

Render a figure to a string using the current color policy.

This follows the same plain-text rendering path as `render!` and `show` for
`MIME"text/plain"`.
"""
function render(fig::Figure)::String
    buffer = IOBuffer()
    io = IOContext(buffer, :color => _color_enabled(stdout))
    render!(io, fig)
    String(take!(buffer))
end

"""
    render!(io, fig)

Render a figure to an arbitrary `IO` stream.

Use `IOContext(io, :color => false)` to suppress ANSI colors or
`IOContext(io, :color => true)` to force them.
An explicit `:color` setting takes precedence over `NO_COLOR`.
"""
function render!(io::IO, fig::Figure)
    write(io, join(_render_lines(fig, io), '\n'))
    nothing
end

function Base.show(io::IO, fig::Figure)
    render!(io, fig)
end

function Base.show(io::IO, ::MIME"text/plain", fig::Figure)
    render!(io, fig)
end
