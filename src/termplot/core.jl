const DEFAULT_PALETTE = (:cyan, :blue, :yellow, :red, :magenta, :green, :white, :black, :gray)
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
const UTC_TZ = TimeZone("UTC")

Base.@kwdef mutable struct Axis
    label::String = ""
    side::Symbol = :left
    limits::Union{Nothing,Tuple{Any,Any}} = nothing
    scale::Symbol = :linear
    tick_count::Int = 6
    date_format::Union{Nothing,DateFormat} = nothing
end

abstract type AbstractSeries end

struct Line{TX<:AbstractVector,TY<:AbstractVector} <: AbstractSeries
    x::TX
    y::TY
    label::String
    color::Union{Nothing,Symbol}
    yside::Symbol
    step::Symbol
    marker::Union{Nothing,Char}
end

struct Stem{TX<:AbstractVector,TY<:AbstractVector} <: AbstractSeries
    x::TX
    y::TY
    label::String
    color::Union{Nothing,Symbol}
    yside::Symbol
    baseline::Float64
    marker::Union{Nothing,Char}
end

struct Scatter{TX<:AbstractVector,TY<:AbstractVector} <: AbstractSeries
    x::TX
    y::TY
    label::String
    color::Union{Nothing,Symbol}
    yside::Symbol
    marker::Char
end

struct Bar{TX<:AbstractVector} <: AbstractSeries
    x::TX
    ys::Vector{AbstractVector}
    labels::Vector{String}
    colors::Vector{Union{Nothing,Symbol}}
    width::Float64
    yside::Symbol
end

struct HLine <: AbstractSeries
    y::Float64
    label::String
    color::Union{Nothing,Symbol}
    yside::Symbol
end

struct VLine{TX} <: AbstractSeries
    x::TX
    label::String
    color::Union{Nothing,Symbol}
end

Base.@kwdef mutable struct Panel
    title::String = ""
    xaxis::Axis = Axis(; side=:bottom)
    yaxis_left::Axis = Axis(; side=:left)
    yaxis_right::Axis = Axis(; side=:right)
    series::Vector{AbstractSeries} = AbstractSeries[]
end

struct GridSeam
    style::Symbol
    gap::Int
end

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
    masks::Matrix{UInt8}
    mask_colors::Matrix{Union{Nothing,Symbol}}
    mask_color_layers::Matrix{Vector{Pair{Symbol,UInt8}}}
    fills::Matrix{UInt8}
    fill_colors::Matrix{Union{Nothing,Symbol}}
    guides::Matrix{Char}
    guide_colors::Matrix{Union{Nothing,Symbol}}
    overlays::Matrix{Char}
    overlay_colors::Matrix{Union{Nothing,Symbol}}
end

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

function GridSeam(style::Symbol=:separate; gap::Integer=style === :adjacent ? 0 : 1)
    style in (:separate, :adjacent) || throw(ArgumentError("unsupported seam style $(style)"))
    gap >= 0 || throw(ArgumentError("seam gap must be >= 0"))
    style === :adjacent && gap != 0 && throw(ArgumentError("adjacent seams must use gap=0"))
    GridSeam(style, Int(gap))
end

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

yside_symbol(yside::Symbol) = yside
yside_symbol(yside::Integer) = yside == 2 ? :right : :left

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
        Float64(width),
        yside_symbol(yside),
    )
end

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
        Float64(width),
        yside_symbol(yside),
    )
end

function HLine(
    y::Real;
    label::AbstractString="",
    color=nothing,
    yside::Union{Symbol,Integer}=:left,
)
    HLine(Float64(y), String(label), normalize_color(color), yside_symbol(yside))
end

function VLine(
    x;
    label::AbstractString="",
    color=nothing,
)
    VLine(x, String(label), normalize_color(color))
end

_resolve_series_color(color::Nothing, ix::Int) = DEFAULT_PALETTE[mod1(ix, length(DEFAULT_PALETTE))]
_resolve_series_color(color::Symbol, ::Int) = color

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
