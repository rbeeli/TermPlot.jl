const DEFAULT_PALETTE = (:cyan, :blue, :yellow, :red, :magenta, :green, :white, :black, :gray)
const DEFAULT_STACKED_BAR_FILL_CHARS = ('█', '▓', '▒', '░', '▩', '▦', '▨', '▧')
const ANSI_CODES = Dict{Symbol,String}(
    :black => "\e[30m",
    :red => "\e[31m",
    :green => "\e[32m",
    :yellow => "\e[33m",
    :blue => "\e[34m",
    :magenta => "\e[35m",
    :cyan => "\e[36m",
    :white => "\e[37m",
    :gray => "\e[90m",
)
const UTC_TZ = tz"UTC"

"""
    Axis

Axis configuration for one panel edge.

`Axis` stores the label, scale, tick target, optional explicit limits, and
optional date/time format used during rendering.
"""
Base.@kwdef mutable struct Axis
    label::String = ""
    side::Symbol = :left
    limits::Union{Nothing,Tuple{Any,Any}} = nothing
    scale::Symbol = :linear
    tick_count::Int = 6
    date_format::Union{Nothing,DateFormat} = nothing
end

abstract type AbstractSeries end

"""
    Line

Connected line series rendered with braille rasterization and optional markers.
"""
struct Line{TX<:AbstractVector,TY<:AbstractVector} <: AbstractSeries
    x::TX
    y::TY
    label::String
    color::Union{Nothing,Symbol}
    yside::Symbol
    step::Symbol
    marker::Union{Nothing,Char}
end

"""
    Stem

Stem plot series with a configurable baseline and optional endpoint markers.
"""
struct Stem{TX<:AbstractVector,TY<:AbstractVector} <: AbstractSeries
    x::TX
    y::TY
    label::String
    color::Union{Nothing,Symbol}
    yside::Symbol
    baseline::Float64
    marker::Union{Nothing,Char}
end

"""
    Scatter

Point-only series rendered with a marker at each valid sample.
"""
struct Scatter{TX<:AbstractVector,TY<:AbstractVector} <: AbstractSeries
    x::TX
    y::TY
    label::String
    color::Union{Nothing,Symbol}
    yside::Symbol
    marker::Char
end

"""
    Bar

Bar or stacked-bar series with one or more y vectors over shared x values.
"""
struct Bar{TX<:AbstractVector} <: AbstractSeries
    x::TX
    ys::Vector{AbstractVector}
    labels::Vector{String}
    colors::Vector{Union{Nothing,Symbol}}
    fillchars::Vector{Char}
    width::Float64
    yside::Symbol
end

"""
    HLine

Horizontal reference line attached to the left or right y-axis.
"""
struct HLine <: AbstractSeries
    y::Float64
    label::String
    color::Union{Nothing,Symbol}
    yside::Symbol
end

"""
    VLine

Vertical reference line attached to the x-axis.
"""
struct VLine{TX} <: AbstractSeries
    x::TX
    label::String
    color::Union{Nothing,Symbol}
end

"""
    Annotation

Text annotation anchored either in axis coordinates or in plot-relative
(`:paper`) coordinates.
"""
struct Annotation{TX,TY} <: AbstractSeries
    x::TX
    y::TY
    text::String
    xref::Symbol
    yref::Symbol
    xanchor::Symbol
    yanchor::Symbol
    align::Symbol
    xshift::Int
    yshift::Int
    color::Union{Nothing,Symbol}
end

"""
    Panel

A subplot inside a `Figure`.

Panels hold their own axes and series. In normal use you obtain them from
`panel!` rather than constructing them manually.
"""
Base.@kwdef mutable struct Panel
    title::String = ""
    xaxis::Axis = Axis(; side=:bottom)
    yaxis_left::Axis = Axis(; side=:left)
    yaxis_right::Axis = Axis(; side=:right)
    series::Vector{AbstractSeries} = AbstractSeries[]
end

"""
    GridSeam

Seam configuration between neighboring rows or columns in a `GridLayout`.
"""
struct GridSeam
    style::Symbol
    gap::Int
end

"""
    GridLayout

Grid definition for multi-panel figures.

`GridLayout` controls row and column counts, relative track weights, seam
styles, and optional alignment groups for shared plot geometry.
"""
struct GridLayout
    rows::Int
    cols::Int
    rowweights::Vector{Float64}
    colweights::Vector{Float64}
    rowseams::Vector{GridSeam}
    colseams::Vector{GridSeam}
    rowaligns::Vector{Int}
    colaligns::Vector{Int}
end

struct PanelPlacement
    rows::UnitRange{Int}
    cols::UnitRange{Int}
    panel::Panel
end

"""
    Figure

Top-level chart container.

A `Figure` owns the layout, panel placements, shared rendering options, and the
current panel used by plotting calls that target the figure directly.
"""
mutable struct Figure
    title::String
    width::Union{Nothing,Int}
    height::Int
    layout::GridLayout
    placements::Vector{PanelPlacement}
    current::Union{Nothing,Panel}
    linkx::Bool
    linky::Bool
    legend::Bool
end

struct XContext
    kind::Symbol
    timezone::Union{Nothing,TimeZone}
    categories::Vector{String}
    category_map::Dict{String,Float64}
end

struct AxisInfo
    limits::Tuple{Float64,Float64}
    ticks::Vector{Float64}
    tick_labels::Vector{String}
    scale::Symbol
end

struct PreparedPanel
    panel::Panel
    xcontext::XContext
    xaxis::AxisInfo
    yleft::AxisInfo
    yright::AxisInfo
    left_width::Int
    right_width::Int
    has_right_axis::Bool
end

struct PlotCanvas
    dot_visible::BitArray{3}
    dot_colors::Array{Union{Nothing,Symbol},3}
    dot_orders::Array{Int,3}
    fill_visible::BitArray{3}
    fill_colors::Array{Union{Nothing,Symbol},3}
    fill_chars::Array{Char,3}
    fill_orders::Array{Int,3}
    guide_horizontal::BitMatrix
    guide_vertical::BitMatrix
    guide_colors::Matrix{Union{Nothing,Symbol}}
    guide_orders::Matrix{Int}
    text_heads::Matrix{String}
    text_colors::Matrix{Union{Nothing,Symbol}}
    text_orders::Matrix{Int}
    text_widths::Matrix{Int}
    text_continuations::BitMatrix
end

"""
    GridLayout(
        rows,
        cols;
        rowweights=fill(1.0, rows),
        colweights=fill(1.0, cols),
        rowseams=GridSeam(:separate; gap=1),
        colseams=GridSeam(:separate; gap=3),
        rowaligns=:none,
        colaligns=:none,
    )

Create a grid layout for a multi-panel figure.

`rowweights` and `colweights` control relative track sizes. `rowseams` and
`colseams` accept either one seam specification or one per internal boundary.
`rowaligns` and `colaligns` accept `:none`, `:all`, booleans, `nothing`, or a
vector of alignment-group labels.

# Keywords

- `rowweights`, `colweights`: positive finite relative track sizes
- `rowseams`, `colseams`: one `GridSeam`/style for all internal seams or one per seam
- `rowaligns`, `colaligns`: `:none`, `:all`, `true`, `false`, `nothing`, or a
  vector of alignment-group labels
"""
function GridLayout(
    rows::Integer,
    cols::Integer;
    rowweights::AbstractVector=fill(1.0, Int(rows)),
    colweights::AbstractVector=fill(1.0, Int(cols)),
    rowseams=GridSeam(:separate; gap=1),
    colseams=GridSeam(:separate; gap=3),
    rowaligns=:none,
    colaligns=:none,
)
    rows >= 1 || throw(ArgumentError("layout rows must be >= 1"))
    cols >= 1 || throw(ArgumentError("layout cols must be >= 1"))
    GridLayout(
        Int(rows),
        Int(cols),
        _normalize_layout_weights(rowweights, Int(rows), :rowweights),
        _normalize_layout_weights(colweights, Int(cols), :colweights),
        _normalize_layout_seams(rowseams, max(Int(rows) - 1, 0), :rowseams),
        _normalize_layout_seams(colseams, max(Int(cols) - 1, 0), :colseams),
        _normalize_layout_aligns(rowaligns, Int(rows), :rowaligns),
        _normalize_layout_aligns(colaligns, Int(cols), :colaligns),
    )
end

"""
    GridSeam(style=:separate; gap=style === :adjacent ? 0 : 1)

Create a seam specification for a grid boundary.

Use `:separate` for a visible gap or `:adjacent` for a shared border with no
gap.

# Arguments

- `style`: `:separate` or `:adjacent`
- `gap`: non-negative integer spacing; must be `0` for `:adjacent`
"""
function GridSeam(style::Symbol=:separate; gap::Integer=style === :adjacent ? 0 : 1)
    style in (:separate, :adjacent) || throw(ArgumentError("unsupported seam style $(style)"))
    gap >= 0 || throw(ArgumentError("seam gap must be >= 0"))
    style === :adjacent && gap != 0 && throw(ArgumentError("adjacent seams must use gap=0"))
    GridSeam(style, Int(gap))
end

"""
    Figure(; title="", width=nothing, height=24, layout=GridLayout(1, 1), linkx=false, linky=false, legend=true)

Create a `Figure`.

`width` defaults to the active display width, `height` is clamped to a minimum
usable size, and `linkx` / `linky` enable shared axis limits across panels.

# Keywords

- `title`: figure title
- `width`: total output width; `nothing` lets the terminal renderer decide
- `height`: total output height
- `layout`: `GridLayout` describing the panel grid
- `linkx`: share x limits across panels
- `linky`: share y limits across panels, per side
- `legend`: show the combined legend/header content
"""
function Figure(;
    title::AbstractString="",
    width::Union{Nothing,Int}=nothing,
    height::Int=24,
    layout::GridLayout=GridLayout(1, 1),
    linkx::Bool=false,
    linky::Bool=false,
    legend::Bool=true,
)
    Figure(String(title), width, max(height, 12), layout, PanelPlacement[], nothing, linkx, linky, legend)
end

Figure(layout::GridLayout; kwargs...) = Figure(; layout, kwargs...)

function _make_panel(;
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
    _validate_scale(xscale, :x)
    _validate_scale(yscale, :y)
    _validate_scale(y2scale, :y)
    Panel(
        String(title),
        Axis(; label=String(xlabel), side=:bottom, scale=xscale, tick_count=max(xfrequency, 2), date_format=x_date_format),
        Axis(; label=String(ylabel), side=:left, scale=yscale, tick_count=max(yfrequency, 2)),
        Axis(; label=String(ylabel_right), side=:right, scale=y2scale, tick_count=max(yfrequency, 2)),
        AbstractSeries[],
    )
end

function currentpanel(fig::Figure)
    !isnothing(fig.current) && return fig.current
    isempty(fig.placements) && throw(ArgumentError("figure has no panels; add one with panel! first"))
    fig.placements[end].panel
end

currentpanel(panel::Panel) = panel

normalize_color(::Nothing) = nothing
normalize_color(color::Symbol) = color === :grey ? :gray : color
normalize_color(color::AbstractString) = normalize_color(Symbol(lowercase(String(color))))

normalize_marker(::Nothing) = nothing
normalize_marker(marker::Char)::Char = marker
normalize_marker(marker::Symbol)::Char = normalize_marker(String(marker))

function normalize_marker(marker::AbstractString)::Char
    marker_lc = lowercase(String(marker))
    marker_lc == "dot" && return '•'
    marker_lc == "hd" && return '◆'
    marker_lc == "diamond" && return '◆'
    marker_lc == "cross" && return 'x'
    marker_lc == "square" && return '■'
    marker_lc == "circle" && return 'o'
    chars = collect(String(marker))
    length(chars) == 1 && return chars[1]
    throw(ArgumentError("marker must be a predefined name or a single character"))
end

function yside_symbol(yside::Symbol)::Symbol
    yside in (:left, :right) || throw(ArgumentError("yside must be :left, :right, 1, or 2"))
    yside
end

function yside_symbol(yside::Integer)::Symbol
    yside == 1 && return :left
    yside == 2 && return :right
    throw(ArgumentError("yside must be :left, :right, 1, or 2"))
end

"""
    Line(x, y; label="", color=nothing, yside=:left, step=:linear, marker=nothing)

Construct a line series.

# Keywords

- `label`: legend label
- `color`: color symbol or string such as `:cyan` or `"cyan"`
- `yside`: `:left`, `:right`, `1`, or `2`
- `step`: `:linear`, `:pre`, `:mid`, or `:post`
- `marker`: `nothing`, a named marker (`"dot"`, `"diamond"`, `"cross"`,
  `"square"`, `"circle"`, `"hd"`), or a single character
"""
function Line(
    x::AbstractVector,
    y::AbstractVector;
    label::AbstractString="",
    color=nothing,
    yside::Union{Symbol,Integer}=:left,
    step::Union{Symbol,AbstractString}=:linear,
    marker::Union{Nothing,Symbol,AbstractString,Char}=nothing,
)
    length(x) == length(y) || throw(ArgumentError("line x/y lengths must match"))
    Line(
        x,
        y,
        String(label),
        normalize_color(color),
        yside_symbol(yside),
        _normalize_line_step(step),
        normalize_marker(marker),
    )
end

"""
    Scatter(x, y; label="", color=nothing, yside=:left, marker="dot")

Construct a scatter series.

# Keywords

- `label`: legend label
- `color`: color symbol or string such as `:cyan` or `"cyan"`
- `yside`: `:left`, `:right`, `1`, or `2`
- `marker`: a named marker (`"dot"`, `"diamond"`, `"cross"`, `"square"`,
  `"circle"`, `"hd"`) or a single character
"""
function Scatter(
    x::AbstractVector,
    y::AbstractVector;
    label::AbstractString="",
    color=nothing,
    yside::Union{Symbol,Integer}=:left,
    marker::Union{Symbol,AbstractString,Char}="dot",
)
    length(x) == length(y) || throw(ArgumentError("scatter x/y lengths must match"))
    Scatter(x, y, String(label), normalize_color(color), yside_symbol(yside), normalize_marker(marker))
end

"""
    Stem(x, y; label="", color=nothing, yside=:left, baseline=0.0, marker="dot")

Construct a stem series.

# Keywords

- `label`: legend label
- `color`: color symbol or string such as `:cyan` or `"cyan"`
- `yside`: `:left`, `:right`, `1`, or `2`
- `baseline`: finite numeric stem baseline
- `marker`: `nothing`, a named marker (`"dot"`, `"diamond"`, `"cross"`,
  `"square"`, `"circle"`, `"hd"`), or a single character
"""
function Stem(
    x::AbstractVector,
    y::AbstractVector;
    label::AbstractString="",
    color=nothing,
    yside::Union{Symbol,Integer}=:left,
    baseline::Real=0.0,
    marker::Union{Nothing,Symbol,AbstractString,Char}="dot",
)
    length(x) == length(y) || throw(ArgumentError("stem x/y lengths must match"))
    baseline_value = Float64(baseline)
    isfinite(baseline_value) || throw(ArgumentError("stem baseline must be finite"))
    Stem(
        x,
        y,
        String(label),
        normalize_color(color),
        yside_symbol(yside),
        baseline_value,
        normalize_marker(marker),
    )
end

function _normalize_bar_width(width::Real)::Float64
    width_value = Float64(width)
    isfinite(width_value) && width_value > 0.0 || throw(ArgumentError("bar width must be positive finite"))
    width_value
end

"""
    Bar(x, y; label="", color=nothing, width=0.8, yside=:left)

Construct a single-series bar chart.

# Keywords

- `label`: legend label
- `color`: fill color
- `width`: positive finite bar width in x-axis units
- `yside`: `:left`, `:right`, `1`, or `2`
"""
function Bar(
    x::AbstractVector,
    y::AbstractVector;
    label::AbstractString="",
    color=nothing,
    width::Real=0.8,
    yside::Union{Symbol,Integer}=:left,
)
    length(y) == length(x) || throw(ArgumentError("bar x/y lengths must match"))
    Bar(
        x,
        AbstractVector[y],
        [String(label)],
        Union{Nothing,Symbol}[normalize_color(color)],
        ['█'],
        _normalize_bar_width(width),
        yside_symbol(yside),
    )
end

"""
    Bar(x, ys...; labels, colors=fill(nothing, length(ys)), width=0.8, yside=:left)

Construct a stacked bar chart.

Stack layers use distinct monochrome fill textures by default so they remain
distinguishable when ANSI color is disabled.

# Keywords

- `labels`: one label per stack component
- `colors`: one color per stack component
- `width`: positive finite bar width in x-axis units
- `yside`: `:left`, `:right`, `1`, or `2`
"""
function Bar(
    x::AbstractVector,
    ys::AbstractVector...;
    labels::AbstractVector{<:AbstractString},
    colors::AbstractVector=fill(nothing, length(ys)),
    width::Real=0.8,
    yside::Union{Symbol,Integer}=:left,
)
    length(labels) == length(ys) || throw(ArgumentError("bar labels must match number of series"))
    length(colors) == length(ys) || throw(ArgumentError("bar colors must match number of series"))
    for y in ys
        length(y) == length(x) || throw(ArgumentError("all bar series must have the same length as x"))
    end
    Bar(
        x,
        AbstractVector[ys...],
        String.(labels),
        Union{Nothing,Symbol}[normalize_color(color) for color in colors],
        _default_stacked_bar_fillchars(length(ys)),
        _normalize_bar_width(width),
        yside_symbol(yside),
    )
end

function _default_stacked_bar_fillchars(count::Int)::Vector{Char}
    count >= 0 || throw(ArgumentError("stacked bar layer count must be non-negative"))
    [DEFAULT_STACKED_BAR_FILL_CHARS[mod1(ix, length(DEFAULT_STACKED_BAR_FILL_CHARS))] for ix in 1:count]
end

"""
    HLine(y; label="", color=nothing, yside=:left)

Construct a horizontal reference line.

# Keywords

- `label`: legend label
- `color`: line color
- `yside`: `:left`, `:right`, `1`, or `2`
"""
function HLine(
    y::Real;
    label::AbstractString="",
    color=nothing,
    yside::Union{Symbol,Integer}=:left,
)
    HLine(Float64(y), String(label), normalize_color(color), yside_symbol(yside))
end

"""
    VLine(x; label="", color=nothing)

Construct a vertical reference line.

# Keywords

- `label`: legend label
- `color`: line color
"""
function VLine(
    x;
    label::AbstractString="",
    color=nothing,
)
    VLine(x, String(label), normalize_color(color))
end

"""
    Annotation(x, y, text; xref=:x, yref=:y, xanchor=:center, yanchor=:middle, align=:center, xshift=0, yshift=0, color=nothing)

Construct a text annotation.

`xref` and `yref` control how the coordinates are interpreted:

- `xref=:x`: x position in x-axis space
- `xref=:paper` or `xref=:plot`: x position relative to the plot area
- `yref=:y`: y position in the left y-axis space
- `yref=:y2`: y position in the right y-axis space
- `yref=:paper` or `yref=:plot`: y position relative to the plot area

`xanchor` and `yanchor` define which point of the annotation box is attached to
`(x, y)`. Use `xanchor=:left/:center/:right` and
`yanchor=:top/:middle/:bottom` to cover corners, edge midpoints, and center.

`align` controls multi-line text alignment inside the annotation box.
`xshift` and `yshift` apply a final position shift in terminal character cells.
Positive `xshift` moves right, positive `yshift` moves down.

# Keywords

- `xref`: `:x`, `:paper`, or `:plot`
- `yref`: `:y`, `:y2`, `:paper`, or `:plot`
- `xanchor`: `:left`, `:center`, or `:right`
- `yanchor`: `:top`, `:middle`, `:bottom`, or `:center`
- `align`: `:left`, `:center`, or `:right`
- `xshift`: integer horizontal shift in character cells
- `yshift`: integer vertical shift in character rows
- `color`: annotation text color
"""
function Annotation(
    x,
    y,
    text::AbstractString;
    xref::Union{Symbol,AbstractString}=:x,
    yref::Union{Symbol,AbstractString}=:y,
    xanchor::Union{Symbol,AbstractString}=:center,
    yanchor::Union{Symbol,AbstractString}=:middle,
    align::Union{Symbol,AbstractString}=:center,
    xshift=0,
    yshift=0,
    color=nothing,
)
    normalized_xref = _normalize_annotation_xref(xref)
    normalized_yref = _normalize_annotation_yref(yref)
    normalized_xref === :paper && _validate_annotation_paper_coord(x, :x)
    _validate_annotation_ycoord(y, normalized_yref)
    Annotation(
        x,
        y,
        replace(String(text), "\r\n" => "\n", '\r' => '\n'),
        normalized_xref,
        normalized_yref,
        _normalize_annotation_xanchor(xanchor),
        _normalize_annotation_yanchor(yanchor),
        _normalize_annotation_align(align),
        _normalize_annotation_shift(xshift, :xshift),
        _normalize_annotation_shift(yshift, :yshift),
        normalize_color(color),
    )
end

_resolve_series_color(color::Nothing, ix::Int) = DEFAULT_PALETTE[mod1(ix, length(DEFAULT_PALETTE))]
_resolve_series_color(color::Symbol, ::Int) = color

function _normalize_annotation_xref(xref)::Symbol
    ref = Symbol(lowercase(String(xref)))
    ref === :plot && return :paper
    ref in (:x, :paper) || throw(ArgumentError("xref must be :x, :paper, or :plot"))
    ref
end

function _normalize_annotation_yref(yref)::Symbol
    ref = Symbol(lowercase(String(yref)))
    ref === :plot && return :paper
    ref === :left && return :y
    ref === :right && return :y2
    ref in (:y, :y2, :paper) || throw(ArgumentError("yref must be :y, :y2, :paper, or :plot"))
    ref
end

function _normalize_annotation_xanchor(xanchor)::Symbol
    anchor = Symbol(lowercase(String(xanchor)))
    anchor in (:left, :center, :right) || throw(ArgumentError("xanchor must be :left, :center, or :right"))
    anchor
end

function _normalize_annotation_yanchor(yanchor)::Symbol
    anchor = Symbol(lowercase(String(yanchor)))
    anchor === :center && return :middle
    anchor in (:top, :middle, :bottom) || throw(ArgumentError("yanchor must be :top, :middle, :bottom, or :center"))
    anchor
end

function _normalize_annotation_align(align)::Symbol
    value = Symbol(lowercase(String(align)))
    value in (:left, :center, :right) || throw(ArgumentError("align must be :left, :center, or :right"))
    value
end

function _normalize_annotation_shift(value, name::Symbol)::Int
    value isa Integer && !(value isa Bool) || throw(ArgumentError("$(name) must be an integer number of character cells"))
    Int(value)
end

function _validate_annotation_paper_coord(value, axis_name::Symbol)
    value isa Real || throw(ArgumentError("annotation $(axis_name) coordinate must be real when using :paper / :plot references"))
    isfinite(Float64(value)) || throw(ArgumentError("annotation $(axis_name) coordinate must be finite when using :paper / :plot references"))
    nothing
end

function _validate_annotation_ycoord(value, yref::Symbol)
    value isa Real || throw(ArgumentError("annotation y coordinate must be real"))
    isfinite(Float64(value)) || throw(ArgumentError("annotation y coordinate must be finite"))
    nothing
end

function _validate_scale(scale::Symbol, axis_kind::Symbol)
    allowed = axis_kind === :y ? (:linear, :log10) : (:linear,)
    scale in allowed || throw(ArgumentError("unsupported $(axis_kind)-axis scale $(scale)"))
end

function _normalize_line_step(step::Symbol)::Symbol
    step in (:linear, :pre, :mid, :post) || throw(ArgumentError("unsupported line step mode $(step)"))
    step
end

_normalize_line_step(step::AbstractString) = _normalize_line_step(Symbol(lowercase(String(step))))

function _normalize_layout_weights(weights::AbstractVector, expected::Int, name::Symbol)::Vector{Float64}
    length(weights) == expected || throw(ArgumentError("$(name) must have length $(expected)"))
    values = Float64[]
    for weight in weights
        weight isa Real || throw(ArgumentError("$(name) entries must be real"))
        value = Float64(weight)
        isfinite(value) && value > 0.0 || throw(ArgumentError("$(name) entries must be positive finite values"))
        push!(values, value)
    end
    values
end

_alignment_disabled(spec) = isnothing(spec) || spec === false || spec === :none
_alignment_all(spec) = spec === true || spec === :all

_normalize_layout_seam(seam::GridSeam) = seam
_normalize_layout_seam(style::Symbol) = GridSeam(style)

function _normalize_layout_seams(seams, expected::Int, name::Symbol)::Vector{GridSeam}
    expected == 0 && return GridSeam[]
    if seams isa AbstractVector
        length(seams) == expected || throw(ArgumentError("$(name) must have length $(expected)"))
        return [_normalize_layout_seam(seam) for seam in seams]
    end
    fill(_normalize_layout_seam(seams), expected)
end

function _normalize_layout_aligns(aligns, expected::Int, name::Symbol)::Vector{Int}
    expected == 0 && return Int[]
    if _alignment_disabled(aligns)
        return fill(0, expected)
    elseif _alignment_all(aligns)
        return fill(1, expected)
    elseif aligns isa AbstractVector
        length(aligns) == expected || throw(ArgumentError("$(name) must have length $(expected)"))
        groups = Dict{Any,Int}()
        next_group = Ref(1)
        values = Vector{Int}(undef, expected)
        for (ix, align) in pairs(aligns)
            if _alignment_disabled(align)
                values[ix] = 0
            else
                values[ix] = get!(groups, align) do
                    group = next_group[]
                    next_group[] += 1
                    group
                end
            end
        end
        return values
    end
    throw(ArgumentError("$(name) must be :none, :all, true/false, nothing, or a vector of alignment groups"))
end

function _normalize_span(spec::Int, upper::Int, axis_name::Symbol)::UnitRange{Int}
    1 <= spec <= upper || throw(BoundsError(1:upper, spec))
    spec:spec
end

function _normalize_span(spec::UnitRange{Int}, upper::Int, axis_name::Symbol)::UnitRange{Int}
    isempty(spec) && throw(ArgumentError("$(axis_name) span must not be empty"))
    first(spec) <= last(spec) || throw(ArgumentError("$(axis_name) span must increase"))
    1 <= first(spec) <= upper || throw(BoundsError(1:upper, spec))
    1 <= last(spec) <= upper || throw(BoundsError(1:upper, spec))
    spec
end

_spans_overlap(a::UnitRange{Int}, b::UnitRange{Int}) = max(first(a), first(b)) <= min(last(a), last(b))

function _placement_overlap(rows_a::UnitRange{Int}, cols_a::UnitRange{Int}, rows_b::UnitRange{Int}, cols_b::UnitRange{Int})::Bool
    _spans_overlap(rows_a, rows_b) && _spans_overlap(cols_a, cols_b)
end

function _braille_dot(dx::Int, dy::Int)::UInt8
    if dx == 0
        return UInt8((0x01, 0x02, 0x04, 0x40)[dy + 1])
    end
    UInt8((0x08, 0x10, 0x20, 0x80)[dy + 1])
end
