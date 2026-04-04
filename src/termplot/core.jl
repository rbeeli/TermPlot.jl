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

mutable struct Figure
    title::String
    width::Union{Nothing,Int}
    height::Int
    panels::Matrix{Panel}
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
    fills::Matrix{UInt8}
    fill_colors::Matrix{Union{Nothing,Symbol}}
    guides::Matrix{Char}
    guide_colors::Matrix{Union{Nothing,Symbol}}
    overlays::Matrix{Char}
    overlay_colors::Matrix{Union{Nothing,Symbol}}
end

function Figure(;
    title::AbstractString="",
    width::Union{Nothing,Int}=nothing,
    height::Int=24,
    layout::Tuple{Int,Int}=(1, 1),
    linkx::Bool=false,
    linky::Bool=false,
    legend::Bool=true,
)
    rows, cols = layout
    rows >= 1 || throw(ArgumentError("layout rows must be >= 1"))
    cols >= 1 || throw(ArgumentError("layout cols must be >= 1"))
    panels = Matrix{Panel}(undef, rows, cols)
    for i in eachindex(panels)
        panels[i] = Panel()
    end
    Figure(String(title), width, max(height, 12), panels, linkx, linky, legend)
end

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

currentpanel(fig::Figure) = fig.panels[1, 1]
currentpanel(panel::Panel) = panel

normalize_color(::Nothing) = nothing
normalize_color(color::Symbol) = color === :grey ? :gray : color
normalize_color(color::AbstractString) = normalize_color(Symbol(lowercase(String(color))))

function normalize_marker(marker::AbstractString)::Char
    marker_lc = lowercase(String(marker))
    marker_lc == "hd" && return '◆'
    marker_lc == "diamond" && return '◆'
    marker_lc == "cross" && return 'x'
    marker_lc == "square" && return '■'
    marker_lc == "circle" && return 'o'
    return '•'
end

yside_symbol(yside::Symbol) = yside
yside_symbol(yside::Integer) = yside == 2 ? :right : :left

function Line(
    x::AbstractVector,
    y::AbstractVector;
    label::AbstractString="",
    color=nothing,
    yside::Union{Symbol,Integer}=:left,
)
    length(x) == length(y) || throw(ArgumentError("line x/y lengths must match"))
    Line(x, y, String(label), normalize_color(color), yside_symbol(yside))
end

function Scatter(
    x::AbstractVector,
    y::AbstractVector;
    label::AbstractString="",
    color=nothing,
    yside::Union{Symbol,Integer}=:left,
    marker::AbstractString="dot",
)
    length(x) == length(y) || throw(ArgumentError("scatter x/y lengths must match"))
    Scatter(x, y, String(label), normalize_color(color), yside_symbol(yside), normalize_marker(marker))
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

function _braille_dot(dx::Int, dy::Int)::UInt8
    if dx == 0
        return UInt8((0x01, 0x02, 0x04, 0x40)[dy + 1])
    end
    UInt8((0x08, 0x10, 0x20, 0x80)[dy + 1])
end
