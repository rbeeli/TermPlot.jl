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

function line!(target::Union{Figure,Panel}, x::AbstractVector, y::AbstractVector; kwargs...)
    push!(currentpanel(target), Line(x, y; kwargs...))
end

function stem!(target::Union{Figure,Panel}, x::AbstractVector, y::AbstractVector; kwargs...)
    push!(currentpanel(target), Stem(x, y; kwargs...))
end

function scatter!(target::Union{Figure,Panel}, x::AbstractVector, y::AbstractVector; kwargs...)
    push!(currentpanel(target), Scatter(x, y; kwargs...))
end

function bar!(target::Union{Figure,Panel}, x::AbstractVector, y::AbstractVector; kwargs...)
    push!(currentpanel(target), Bar(x, y; kwargs...))
end

function stackedbar!(target::Union{Figure,Panel}, x::AbstractVector, ys::AbstractVector...; kwargs...)
    push!(currentpanel(target), Bar(x, ys...; kwargs...))
end

function hline!(target::Union{Figure,Panel}, y::Real; kwargs...)
    push!(currentpanel(target), HLine(y; kwargs...))
end

function vline!(target::Union{Figure,Panel}, x; kwargs...)
    push!(currentpanel(target), VLine(x; kwargs...))
end

function xlims!(target::Union{Figure,Panel}, lower, upper)
    panel = currentpanel(target)
    panel.xaxis.limits = (lower, upper)
    target
end

function ylims!(target::Union{Figure,Panel}, lower::Real, upper::Real; yside::Union{Symbol,Integer}=:left)
    axis = yside_symbol(yside) === :right ? currentpanel(target).yaxis_right : currentpanel(target).yaxis_left
    axis.limits = (Float64(lower), Float64(upper))
    target
end

function yscale!(target::Union{Figure,Panel}, scale::Symbol; yside::Union{Symbol,Integer}=:left)
    _validate_scale(scale, :y)
    axis = yside_symbol(yside) === :right ? currentpanel(target).yaxis_right : currentpanel(target).yaxis_left
    axis.scale = scale
    target
end

function render(fig::Figure)::String
    buffer = IOBuffer()
    io = IOContext(buffer, :color => _color_enabled(stdout))
    render!(io, fig)
    String(take!(buffer))
end

function render!(io::IO, fig::Figure)
    write(io, join(_render_lines(fig, io), '\n'))
    nothing
end

function Base.show(io::IO, ::MIME"text/plain", fig::Figure)
    render!(io, fig)
end
