abstract type AbstractDrawPrimitive end

struct DotPrimitive <: AbstractDrawPrimitive
    subx::Int
    suby::Int
    color::Symbol
    order::Int
end

struct SegmentPrimitive <: AbstractDrawPrimitive
    x0::Float64
    y0::Float64
    x1::Float64
    y1::Float64
    color::Symbol
    order::Int
end

struct MarkerPrimitive <: AbstractDrawPrimitive
    row::Int
    col::Int
    text::String
    width::Int
    color::Union{Nothing,Symbol}
    order::Int
end

struct GuideSpanPrimitive <: AbstractDrawPrimitive
    orientation::Symbol
    fixed::Int
    start::Int
    stop::Int
    color::Symbol
    order::Int
end

struct FillRectPrimitive <: AbstractDrawPrimitive
    xmin::Int
    xmax::Int
    ymin::Int
    ymax::Int
    color::Symbol
    order::Int
end

const DrawPrimitive = Union{DotPrimitive,SegmentPrimitive,MarkerPrimitive,GuideSpanPrimitive,FillRectPrimitive}
const BRAILLE_DOT_MASKS = (
    UInt8(0x01),
    UInt8(0x02),
    UInt8(0x04),
    UInt8(0x40),
    UInt8(0x08),
    UInt8(0x10),
    UInt8(0x20),
    UInt8(0x80),
)

function _render_plot_canvas(prepared::PreparedPanel, plot_width::Int, plot_height::Int)::PlotCanvas
    canvas = _empty_plot_canvas(plot_width, plot_height)
    for primitive in _collect_primitives(prepared, plot_width, plot_height)
        _apply_primitive!(canvas, primitive)
    end
    canvas
end

function _empty_plot_canvas(plot_width::Int, plot_height::Int)::PlotCanvas
    dot_visible = falses(8, plot_height, plot_width)
    dot_colors = Array{Union{Nothing,Symbol}}(undef, 8, plot_height, plot_width)
    fill!(dot_colors, nothing)
    dot_orders = fill(0, 8, plot_height, plot_width)

    fill_visible = falses(4, plot_height, plot_width)
    fill_colors = Array{Union{Nothing,Symbol}}(undef, 4, plot_height, plot_width)
    fill!(fill_colors, nothing)
    fill_orders = fill(0, 4, plot_height, plot_width)

    guide_horizontal = falses(plot_height, plot_width)
    guide_vertical = falses(plot_height, plot_width)
    guide_colors = Matrix{Union{Nothing,Symbol}}(undef, plot_height, plot_width)
    fill!(guide_colors, nothing)
    guide_orders = fill(0, plot_height, plot_width)

    text_heads = fill("", plot_height, plot_width)
    text_colors = Matrix{Union{Nothing,Symbol}}(undef, plot_height, plot_width)
    fill!(text_colors, nothing)
    text_orders = fill(0, plot_height, plot_width)
    text_widths = fill(0, plot_height, plot_width)
    text_continuations = falses(plot_height, plot_width)

    PlotCanvas(
        dot_visible,
        dot_colors,
        dot_orders,
        fill_visible,
        fill_colors,
        fill_orders,
        guide_horizontal,
        guide_vertical,
        guide_colors,
        guide_orders,
        text_heads,
        text_colors,
        text_orders,
        text_widths,
        text_continuations,
    )
end

function _collect_primitives(prepared::PreparedPanel, plot_width::Int, plot_height::Int)::Vector{DrawPrimitive}
    primitives = DrawPrimitive[]
    auto_ix = 0
    next_order = 1
    for series in prepared.panel.series
        if series isa Line
            color = _resolve_series_color(series.color, auto_ix += 1)
            next_order = _append_line_primitives!(primitives, prepared, series, plot_width, plot_height, color, next_order)
        elseif series isa Stem
            color = _resolve_series_color(series.color, auto_ix += 1)
            next_order = _append_stem_primitives!(primitives, prepared, series, plot_width, plot_height, color, next_order)
        elseif series isa Scatter
            color = _resolve_series_color(series.color, auto_ix += 1)
            next_order = _append_scatter_primitives!(primitives, prepared, series, plot_width, plot_height, color, next_order)
        elseif series isa Bar
            next_order = _append_bar_primitives!(primitives, prepared, series, plot_width, plot_height, auto_ix, next_order)
            auto_ix += length(series.labels)
        elseif series isa HLine
            color = _resolve_series_color(series.color, auto_ix += 1)
            next_order = _append_hline_primitives!(primitives, prepared, series, plot_width, plot_height, color, next_order)
        elseif series isa VLine
            color = _resolve_series_color(series.color, auto_ix += 1)
            next_order = _append_vline_primitives!(primitives, prepared, series, plot_width, plot_height, color, next_order)
        elseif series isa Annotation
            next_order = _append_annotation_primitives!(primitives, prepared, series, plot_width, plot_height, next_order)
        end
    end
    primitives
end

function _append_line_primitives!(
    primitives::Vector{DrawPrimitive},
    prepared::PreparedPanel,
    series::Line,
    plot_width::Int,
    plot_height::Int,
    color::Symbol,
    next_order::Int,
)::Int
    xcontext = prepared.xcontext
    yaxis = series.yside === :right ? prepared.yright : prepared.yleft
    subwidth = plot_width * 2
    subheight = plot_height * 4
    npoints = min(length(series.x), length(series.y))
    points = Vector{Union{Nothing,Tuple{Float64,Float64}}}(undef, npoints)
    visible_points = Vector{Union{Nothing,Tuple{Int,Int}}}(undef, npoints)

    for (idx, (x_raw, y_raw)) in enumerate(zip(series.x, series.y))
        point = _series_subpoint(xcontext, prepared.xaxis, yaxis, x_raw, y_raw, subwidth, subheight)
        points[idx] = point
        visible_points[idx] = isnothing(point) || !_point_in_bounds(point, subwidth, subheight) ? nothing : (round(Int, point[1]), round(Int, point[2]))
    end

    prev = nothing
    for point in points
        if isnothing(point)
            prev = nothing
            continue
        end
        if !isnothing(prev)
            next_order = _append_segment_primitives!(primitives, prev, point, series.step, subwidth, subheight, color, next_order)
        end
        prev = point
    end

    if isnothing(series.marker)
        for idx in eachindex(points)
            visible_point = visible_points[idx]
            isnothing(visible_point) && continue
            prev_connected = idx > firstindex(points) && !isnothing(points[idx - 1])
            next_connected = idx < lastindex(points) && !isnothing(points[idx + 1])
            if !prev_connected && !next_connected
                push!(primitives, DotPrimitive(visible_point[1], visible_point[2], color, next_order))
                next_order += 1
            end
        end
    else
        for visible_point in visible_points
            isnothing(visible_point) && continue
            next_order = _append_marker_primitive!(primitives, visible_point, series.marker, plot_width, plot_height, color, next_order)
        end
    end
    next_order
end

function _append_stem_primitives!(
    primitives::Vector{DrawPrimitive},
    prepared::PreparedPanel,
    series::Stem,
    plot_width::Int,
    plot_height::Int,
    color::Symbol,
    next_order::Int,
)::Int
    xcontext = prepared.xcontext
    yaxis = series.yside === :right ? prepared.yright : prepared.yleft
    subwidth = plot_width * 2
    subheight = plot_height * 4
    marker_points = Tuple{Int,Int}[]

    for (x_raw, y_raw) in zip(series.x, series.y)
        point = _series_subpoint(xcontext, prepared.xaxis, yaxis, x_raw, y_raw, subwidth, subheight)
        isnothing(point) && continue
        baseline_point = _series_subpoint(xcontext, prepared.xaxis, yaxis, x_raw, series.baseline, subwidth, subheight)
        isnothing(baseline_point) && continue

        clipped = _clip_line(
            baseline_point[1],
            baseline_point[2],
            point[1],
            point[2],
            0.0,
            Float64(subwidth - 1),
            0.0,
            Float64(subheight - 1),
        )
        if !isnothing(clipped)
            push!(primitives, SegmentPrimitive(clipped[1], clipped[2], clipped[3], clipped[4], color, next_order))
            next_order += 1
        end

        visible_point = _point_in_bounds(point, subwidth, subheight) ? (round(Int, point[1]), round(Int, point[2])) : nothing
        if !isnothing(series.marker) && !isnothing(visible_point)
            push!(marker_points, visible_point)
        end
    end

    if !isnothing(series.marker)
        for visible_point in marker_points
            next_order = _append_marker_primitive!(primitives, visible_point, series.marker, plot_width, plot_height, color, next_order)
        end
    end
    next_order
end

function _append_scatter_primitives!(
    primitives::Vector{DrawPrimitive},
    prepared::PreparedPanel,
    series::Scatter,
    plot_width::Int,
    plot_height::Int,
    color::Symbol,
    next_order::Int,
)::Int
    xcontext = prepared.xcontext
    yaxis = series.yside === :right ? prepared.yright : prepared.yleft
    for (x_raw, y_raw) in zip(series.x, series.y)
        point = _series_point(xcontext, prepared.xaxis, yaxis, x_raw, y_raw, plot_width * 2, plot_height * 4)
        isnothing(point) && continue
        next_order = _append_marker_primitive!(primitives, point, series.marker, plot_width, plot_height, color, next_order)
    end
    next_order
end

function _append_bar_primitives!(
    primitives::Vector{DrawPrimitive},
    prepared::PreparedPanel,
    series::Bar,
    plot_width::Int,
    plot_height::Int,
    auto_ix_start::Int,
    next_order::Int,
)::Int
    xcontext = prepared.xcontext
    axis = series.yside === :right ? prepared.yright : prepared.yleft
    positions = [_convert_x(value, xcontext) for value in series.x]
    half_width = _bar_half_width(positions, series.width)
    for bar_ix in eachindex(positions)
        x_center = positions[bar_ix]
        !isfinite(x_center) && continue
        pos_base = 0.0
        neg_base = 0.0
        for stack_ix in eachindex(series.ys)
            y_raw = series.ys[stack_ix][bar_ix]
            y = _finite_y(y_raw)
            isfinite(y) || continue
            color = _resolve_series_color(series.colors[stack_ix], auto_ix_start + stack_ix)
            y_lo = y >= 0.0 ? pos_base : neg_base + y
            y_hi = y >= 0.0 ? pos_base + y : neg_base
            xspan = _clipped_subinterval(x_center - half_width, x_center + half_width, prepared.xaxis, plot_width * 2, _value_to_subx)
            yspan = _clipped_subinterval(y_lo, y_hi, axis, plot_height * 4, _value_to_suby)
            if !isnothing(xspan) && !isnothing(yspan)
                xmin = clamp(min(xspan[1], xspan[2]), 0, plot_width * 2 - 1)
                xmax = clamp(max(xspan[1], xspan[2]), 0, plot_width * 2 - 1)
                ymin = clamp(min(yspan[1], yspan[2]), 0, plot_height * 4 - 1)
                ymax = clamp(max(yspan[1], yspan[2]), 0, plot_height * 4 - 1)
                push!(primitives, FillRectPrimitive(xmin, xmax, ymin, ymax, color, next_order))
                next_order += 1
            end
            if y >= 0.0
                pos_base += y
            else
                neg_base += y
            end
        end
    end
    next_order
end

function _append_hline_primitives!(
    primitives::Vector{DrawPrimitive},
    prepared::PreparedPanel,
    series::HLine,
    plot_width::Int,
    plot_height::Int,
    color::Symbol,
    next_order::Int,
)::Int
    axis = series.yside === :right ? prepared.yright : prepared.yleft
    row = _value_to_suby(series.y, axis, plot_height * 4)
    isnothing(row) && return next_order
    cell_row = clamp(fld(row, 4) + 1, 1, plot_height)
    push!(primitives, GuideSpanPrimitive(:horizontal, cell_row, 1, plot_width, color, next_order))
    next_order + 1
end

function _append_vline_primitives!(
    primitives::Vector{DrawPrimitive},
    prepared::PreparedPanel,
    series::VLine,
    plot_width::Int,
    plot_height::Int,
    color::Symbol,
    next_order::Int,
)::Int
    x = _convert_x(series.x, prepared.xcontext)
    isfinite(x) || return next_order
    col = _value_to_subx(x, prepared.xaxis, plot_width * 2)
    isnothing(col) && return next_order
    cell_col = clamp(fld(col, 2) + 1, 1, plot_width)
    push!(primitives, GuideSpanPrimitive(:vertical, cell_col, 1, plot_height, color, next_order))
    next_order + 1
end

function _append_annotation_primitives!(
    primitives::Vector{DrawPrimitive},
    prepared::PreparedPanel,
    series::Annotation,
    plot_width::Int,
    plot_height::Int,
    next_order::Int,
)::Int
    isempty(series.text) && return next_order
    anchor_col = _annotation_anchor_col(series, prepared, plot_width)
    anchor_row = _annotation_anchor_row(series, prepared, plot_height)
    (isnothing(anchor_col) || isnothing(anchor_row)) && return next_order

    lines = split(series.text, '\n'; keepempty=true)
    widths = [textwidth(line) for line in lines]
    box_width = maximum(widths; init=0)
    top_row = anchor_row - _annotation_y_offset(length(lines), series.yanchor)
    left_col = anchor_col - _annotation_x_offset(box_width, series.xanchor)

    for (line_ix, line) in pairs(lines)
        row = top_row + line_ix - 1
        1 <= row <= plot_height || continue
        line_col = left_col + _annotation_align_offset(box_width, widths[line_ix], series.align)
        next_order = _append_text_primitive!(primitives, row, line_col, line, plot_width, series.color, next_order)
    end
    next_order
end

function _append_segment_primitives!(
    primitives::Vector{DrawPrimitive},
    prev::Tuple{Float64,Float64},
    point::Tuple{Float64,Float64},
    step::Symbol,
    subwidth::Int,
    subheight::Int,
    color::Symbol,
    next_order::Int,
)::Int
    for (x0, y0, x1, y1) in _line_segments(prev, point, step)
        clipped = _clip_line(
            x0,
            y0,
            x1,
            y1,
            0.0,
            Float64(subwidth - 1),
            0.0,
            Float64(subheight - 1),
        )
        isnothing(clipped) && continue
        push!(primitives, SegmentPrimitive(clipped[1], clipped[2], clipped[3], clipped[4], color, next_order))
        next_order += 1
    end
    next_order
end

function _append_marker_primitive!(
    primitives::Vector{DrawPrimitive},
    point::Tuple{Int,Int},
    marker::Char,
    plot_width::Int,
    plot_height::Int,
    color::Symbol,
    next_order::Int,
)::Int
    marker_text = _take_textwidth_prefix(string(marker), plot_width)
    isempty(marker_text) && return next_order
    marker_width = max(textwidth(marker_text), 1)
    cell_col = clamp(fld(point[1], 2) + 1, 1, max(plot_width - marker_width + 1, 1))
    cell_row = clamp(fld(point[2], 4) + 1, 1, plot_height)
    push!(primitives, MarkerPrimitive(cell_row, cell_col, marker_text, marker_width, color, next_order))
    next_order + 1
end

function _append_text_primitive!(
    primitives::Vector{DrawPrimitive},
    row::Int,
    col::Int,
    text::AbstractString,
    plot_width::Int,
    color::Union{Nothing,Symbol},
    next_order::Int,
)::Int
    text_width = textwidth(text)
    text_width <= 0 && return next_order

    visible_start = max(col, 1)
    visible_stop = min(col + text_width - 1, plot_width)
    visible_start <= visible_stop || return next_order

    clipped_text, clipped_width = _textwidth_window(text, max(1 - col, 0), visible_stop - visible_start + 1)
    clipped_width <= 0 && return next_order
    push!(primitives, MarkerPrimitive(row, visible_start, clipped_text, clipped_width, color, next_order))
    next_order + 1
end

function _apply_primitive!(canvas::PlotCanvas, primitive::DotPrimitive)
    _set_subpixel!(canvas, primitive.subx, primitive.suby, primitive.color, primitive.order)
end

function _apply_primitive!(canvas::PlotCanvas, primitive::SegmentPrimitive)
    _draw_segment!(canvas, primitive.x0, primitive.y0, primitive.x1, primitive.y1, primitive.color, primitive.order)
end

function _apply_primitive!(canvas::PlotCanvas, primitive::MarkerPrimitive)
    _write_text_span!(canvas, primitive.row, primitive.col, primitive.text, primitive.width, primitive.color, primitive.order)
end

function _apply_primitive!(canvas::PlotCanvas, primitive::GuideSpanPrimitive)
    if primitive.orientation === :horizontal
        for col in primitive.start:primitive.stop
            _set_guide_cell!(canvas, primitive.fixed, col, :horizontal, primitive.color, primitive.order)
        end
    else
        for row in primitive.start:primitive.stop
            _set_guide_cell!(canvas, row, primitive.fixed, :vertical, primitive.color, primitive.order)
        end
    end
    nothing
end

function _apply_primitive!(canvas::PlotCanvas, primitive::FillRectPrimitive)
    for suby in primitive.ymin:primitive.ymax
        for subx in primitive.xmin:primitive.xmax
            _set_fill_subpixel!(canvas, subx, suby, primitive.color, primitive.order)
        end
    end
    nothing
end

function _line_segments(prev::Tuple{<:Real,<:Real}, point::Tuple{<:Real,<:Real}, step::Symbol)
    x0 = Float64(prev[1])
    y0 = Float64(prev[2])
    x1 = Float64(point[1])
    y1 = Float64(point[2])
    if step === :linear
        return [(x0, y0, x1, y1)]
    elseif step === :post
        return [(x0, y0, x1, y0), (x1, y0, x1, y1)]
    elseif step === :pre
        return [(x0, y0, x0, y1), (x0, y1, x1, y1)]
    end
    xmid = (x0 + x1) / 2
    [(x0, y0, xmid, y0), (xmid, y0, xmid, y1), (xmid, y1, x1, y1)]
end

function _clipped_subinterval(
    lo_value::Float64,
    hi_value::Float64,
    axis::AxisInfo,
    subsize::Int,
    projector::Function,
)::Union{Nothing,Tuple{Int,Int}}
    axis_lo, axis_hi = axis.limits
    value_lo = min(lo_value, hi_value)
    value_hi = max(lo_value, hi_value)
    value_hi < axis_lo && return nothing
    value_lo > axis_hi && return nothing

    clipped_lo = clamp(lo_value, axis_lo, axis_hi)
    clipped_hi = clamp(hi_value, axis_lo, axis_hi)
    sub_lo = projector(clipped_lo, axis, subsize)
    sub_hi = projector(clipped_hi, axis, subsize)
    (isnothing(sub_lo) || isnothing(sub_hi)) && return nothing
    sub_lo, sub_hi
end

function _annotation_anchor_col(series::Annotation, prepared::PreparedPanel, plot_width::Int)::Union{Nothing,Int}
    if series.xref === :x
        x = _convert_x(series.x, prepared.xcontext)
        isfinite(x) || return nothing
        subx = _value_to_subx_unclipped(x, prepared.xaxis, plot_width * 2)
    else
        x = _finite_y(series.x)
        isfinite(x) || return nothing
        subx = x * (plot_width * 2 - 1)
    end
    fld(round(Int, subx), 2) + 1
end

function _annotation_anchor_row(series::Annotation, prepared::PreparedPanel, plot_height::Int)::Union{Nothing,Int}
    if series.yref === :paper
        y = _finite_y(series.y)
        isfinite(y) || return nothing
        suby = (1.0 - y) * (plot_height * 4 - 1)
    else
        y = _finite_y(series.y)
        isfinite(y) || return nothing
        axis = series.yref === :y2 ? prepared.yright : prepared.yleft
        suby = _value_to_suby_unclipped(y, axis, plot_height * 4)
    end
    fld(round(Int, suby), 4) + 1
end

_annotation_x_offset(width::Int, xanchor::Symbol)::Int = xanchor === :left ? 0 : xanchor === :center ? fld(max(width - 1, 0), 2) : max(width - 1, 0)
_annotation_y_offset(height::Int, yanchor::Symbol)::Int = yanchor === :top ? 0 : yanchor === :middle ? fld(max(height - 1, 0), 2) : max(height - 1, 0)
_annotation_align_offset(box_width::Int, line_width::Int, align::Symbol)::Int = align === :left ? 0 : align === :center ? fld(max(box_width - line_width, 0), 2) : max(box_width - line_width, 0)

function _plot_row_string(canvas::PlotCanvas, row::Int, color_enabled::Bool)::String
    io = IOBuffer()
    active = nothing
    col = 1
    last_col = size(canvas.text_heads, 2)
    while col <= last_col
        text, color, advance = _plot_cell(canvas, row, col)
        if color_enabled
            active = _write_color_transition!(io, active, color)
        end
        write(io, text)
        col += advance
    end
    color_enabled && !isnothing(active) && write(io, "\e[0m")
    String(take!(io))
end

function _plot_cell(canvas::PlotCanvas, row::Int, col::Int)::Tuple{String,Union{Nothing,Symbol},Int}
    if canvas.text_widths[row, col] > 0 && _text_head_visible(canvas, row, col)
        width = max(canvas.text_widths[row, col], 1)
        return canvas.text_heads[row, col], canvas.text_colors[row, col], width
    end
    _plot_nontext_cell(canvas, row, col)
end

function _plot_nontext_cell(canvas::PlotCanvas, row::Int, col::Int)::Tuple{String,Union{Nothing,Symbol},Int}
    dot_mask, dot_color, dot_order = _dot_cell_state(canvas, row, col)
    fill_mask, fill_color, fill_order = _fill_cell_state(canvas, row, col)
    guide_char, guide_color, guide_order = _guide_cell_state(canvas, row, col)

    best_order = max(dot_order, fill_order, guide_order)
    best_order == 0 && return " ", nothing, 1
    if guide_order == best_order
        return string(guide_char), guide_color, 1
    elseif fill_order == best_order
        return string(get(QUADRANT_CHARS, fill_mask, '█')), fill_color, 1
    end
    string(Char(0x2800 + dot_mask)), dot_color, 1
end

function _text_head_visible(canvas::PlotCanvas, row::Int, col::Int)::Bool
    width = canvas.text_widths[row, col]
    width <= 0 && return false
    text_order = canvas.text_orders[row, col]
    stop = min(col + width - 1, size(canvas.text_heads, 2))
    for current in col:stop
        _nontext_order(canvas, row, current) > text_order && return false
    end
    true
end

function _nontext_order(canvas::PlotCanvas, row::Int, col::Int)::Int
    _, _, dot_order = _dot_cell_state(canvas, row, col)
    _, _, fill_order = _fill_cell_state(canvas, row, col)
    _, _, guide_order = _guide_cell_state(canvas, row, col)
    max(dot_order, fill_order, guide_order)
end

function _dot_cell_state(canvas::PlotCanvas, row::Int, col::Int)::Tuple{UInt8,Union{Nothing,Symbol},Int}
    mask = UInt8(0)
    color = nothing
    order = 0
    for dot in 1:8
        canvas.dot_visible[dot, row, col] || continue
        mask |= BRAILLE_DOT_MASKS[dot]
        dot_order = canvas.dot_orders[dot, row, col]
        if dot_order >= order
            order = dot_order
            color = canvas.dot_colors[dot, row, col]
        end
    end
    mask, color, order
end

function _fill_cell_state(canvas::PlotCanvas, row::Int, col::Int)::Tuple{UInt8,Union{Nothing,Symbol},Int}
    mask = UInt8(0)
    color = nothing
    order = 0
    for quadrant in 1:4
        canvas.fill_visible[quadrant, row, col] || continue
        mask |= UInt8(1 << (quadrant - 1))
        quadrant_order = canvas.fill_orders[quadrant, row, col]
        if quadrant_order >= order
            order = quadrant_order
            color = canvas.fill_colors[quadrant, row, col]
        end
    end
    mask, color, order
end

function _guide_cell_state(canvas::PlotCanvas, row::Int, col::Int)::Tuple{Char,Union{Nothing,Symbol},Int}
    horizontal = canvas.guide_horizontal[row, col]
    vertical = canvas.guide_vertical[row, col]
    if !horizontal && !vertical
        return '\0', nothing, 0
    end
    char = horizontal && vertical ? '┼' : (horizontal ? '─' : '│')
    char, canvas.guide_colors[row, col], canvas.guide_orders[row, col]
end

function _write_text_span!(
    canvas::PlotCanvas,
    row::Int,
    col::Int,
    text::String,
    width::Int,
    color::Union{Nothing,Symbol},
    order::Int,
)
    stop = min(col + width - 1, size(canvas.text_heads, 2))
    _clear_text_range!(canvas, row, col, stop)
    canvas.text_heads[row, col] = text
    canvas.text_colors[row, col] = color
    canvas.text_orders[row, col] = order
    canvas.text_widths[row, col] = width
    canvas.text_continuations[row, col] = false
    for current in (col + 1):stop
        canvas.text_heads[row, current] = ""
        canvas.text_colors[row, current] = color
        canvas.text_orders[row, current] = order
        canvas.text_widths[row, current] = 0
        canvas.text_continuations[row, current] = true
    end
    nothing
end

function _clear_text_range!(canvas::PlotCanvas, row::Int, col_lo::Int, col_hi::Int)
    ncols = size(canvas.text_heads, 2)
    start = clamp(col_lo, 1, ncols)
    stop = clamp(col_hi, 1, ncols)
    while start > 1 && canvas.text_continuations[row, start]
        start -= 1
    end

    col = start
    while col <= stop
        if canvas.text_widths[row, col] > 0
            span_stop = min(col + canvas.text_widths[row, col] - 1, ncols)
            _clear_text_span!(canvas, row, col, span_stop)
            col = span_stop + 1
        else
            col += 1
        end
    end
    nothing
end

function _clear_text_span!(canvas::PlotCanvas, row::Int, start::Int, stop::Int)
    for col in start:stop
        canvas.text_heads[row, col] = ""
        canvas.text_colors[row, col] = nothing
        canvas.text_orders[row, col] = 0
        canvas.text_widths[row, col] = 0
        canvas.text_continuations[row, col] = false
    end
    nothing
end

function _set_fill_subpixel!(canvas::PlotCanvas, subx::Int, suby::Int, color::Symbol, order::Int)
    cell_row = fld(suby, 4) + 1
    cell_col = fld(subx, 2) + 1
    quadrant = _fill_quadrant_index(mod(subx, 2), mod(suby, 4))
    canvas.fill_visible[quadrant, cell_row, cell_col] = true
    if order >= canvas.fill_orders[quadrant, cell_row, cell_col]
        canvas.fill_orders[quadrant, cell_row, cell_col] = order
        canvas.fill_colors[quadrant, cell_row, cell_col] = color
    end
    nothing
end

function _set_guide_cell!(canvas::PlotCanvas, row::Int, col::Int, orientation::Symbol, color::Symbol, order::Int)
    if orientation === :horizontal
        canvas.guide_horizontal[row, col] = true
    else
        canvas.guide_vertical[row, col] = true
    end
    if order >= canvas.guide_orders[row, col]
        canvas.guide_orders[row, col] = order
        canvas.guide_colors[row, col] = color
    end
    nothing
end

function _write_color_transition!(io::IO, active, next)
    if active === next
        return active
    end
    if isnothing(next)
        !isnothing(active) && write(io, "\e[0m")
    else
        write(io, get(ANSI_CODES, next, ""))
    end
    next
end

function _set_subpixel!(canvas::PlotCanvas, subx::Int, suby::Int, color::Symbol, order::Int)
    cell_row = fld(suby, 4) + 1
    cell_col = fld(subx, 2) + 1
    dot = _braille_dot_index(mod(subx, 2), mod(suby, 4))
    canvas.dot_visible[dot, cell_row, cell_col] = true
    if order >= canvas.dot_orders[dot, cell_row, cell_col]
        canvas.dot_orders[dot, cell_row, cell_col] = order
        canvas.dot_colors[dot, cell_row, cell_col] = color
    end
    nothing
end

function _draw_segment!(canvas::PlotCanvas, x0::Float64, y0::Float64, x1::Float64, y1::Float64, color::Symbol, order::Int)
    ix0 = round(Int, x0)
    iy0 = round(Int, y0)
    ix1 = round(Int, x1)
    iy1 = round(Int, y1)
    dx = abs(ix1 - ix0)
    dy = -abs(iy1 - iy0)
    sx = ix0 < ix1 ? 1 : -1
    sy = iy0 < iy1 ? 1 : -1
    err = dx + dy
    x = ix0
    y = iy0
    while true
        _set_subpixel!(canvas, x, y, color, order)
        x == ix1 && y == iy1 && break
        e2 = 2 * err
        if e2 >= dy
            err += dy
            x += sx
        end
        if e2 <= dx
            err += dx
            y += sy
        end
    end
    nothing
end

function _braille_dot_index(dx::Int, dy::Int)::Int
    if dx == 0
        return dy == 0 ? 1 : dy == 1 ? 2 : dy == 2 ? 3 : 4
    end
    dy == 0 ? 5 : dy == 1 ? 6 : dy == 2 ? 7 : 8
end

_fill_quadrant_index(dx::Int, dy::Int)::Int = dy < 2 ? (dx == 0 ? 1 : 2) : (dx == 0 ? 3 : 4)

const QUADRANT_CHARS = Dict{UInt8,Char}(
    0x00 => ' ',
    0x01 => '▘',
    0x02 => '▝',
    0x03 => '▀',
    0x04 => '▖',
    0x05 => '▌',
    0x06 => '▞',
    0x07 => '▛',
    0x08 => '▗',
    0x09 => '▚',
    0x0a => '▐',
    0x0b => '▜',
    0x0c => '▄',
    0x0d => '▙',
    0x0e => '▟',
    0x0f => '█',
)

function _clip_line(x0::Float64, y0::Float64, x1::Float64, y1::Float64, xmin::Float64, xmax::Float64, ymin::Float64, ymax::Float64)
    outcode(x, y) = (x < xmin ? 1 : 0) | (x > xmax ? 2 : 0) | (y < ymin ? 4 : 0) | (y > ymax ? 8 : 0)
    code0 = outcode(x0, y0)
    code1 = outcode(x1, y1)
    while true
        if (code0 | code1) == 0
            return (x0, y0, x1, y1)
        elseif (code0 & code1) != 0
            return nothing
        end

        code_out = code0 != 0 ? code0 : code1
        if (code_out & 8) != 0
            x = x0 + (x1 - x0) * (ymax - y0) / (y1 - y0)
            y = ymax
        elseif (code_out & 4) != 0
            x = x0 + (x1 - x0) * (ymin - y0) / (y1 - y0)
            y = ymin
        elseif (code_out & 2) != 0
            y = y0 + (y1 - y0) * (xmax - x0) / (x1 - x0)
            x = xmax
        else
            y = y0 + (y1 - y0) * (xmin - x0) / (x1 - x0)
            x = xmin
        end

        if code_out == code0
            x0, y0 = x, y
            code0 = outcode(x0, y0)
        else
            x1, y1 = x, y
            code1 = outcode(x1, y1)
        end
    end
end
