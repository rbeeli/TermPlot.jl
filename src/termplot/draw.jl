function _render_plot_canvas(prepared::PreparedPanel, plot_width::Int, plot_height::Int)::PlotCanvas
    masks = fill(UInt8(0), plot_height, plot_width)
    mask_colors = fill(nothing, plot_height, plot_width)
    mask_color_layers = [Pair{Symbol,UInt8}[] for _ in 1:plot_height, _ in 1:plot_width]
    fills = fill(UInt8(0), plot_height, plot_width)
    fill_colors = fill(nothing, plot_height, plot_width)
    guides = fill('\0', plot_height, plot_width)
    guide_colors = fill(nothing, plot_height, plot_width)
    overlays = fill('\0', plot_height, plot_width)
    overlay_colors = fill(nothing, plot_height, plot_width)
    canvas = PlotCanvas(masks, mask_colors, mask_color_layers, fills, fill_colors, guides, guide_colors, overlays, overlay_colors)

    auto_ix = 0
    for series in prepared.panel.series
        if series isa Line
            color = _resolve_series_color(series.color, auto_ix += 1)
            _draw_line_series!(canvas, prepared, series, plot_width, plot_height, color)
        elseif series isa Stem
            color = _resolve_series_color(series.color, auto_ix += 1)
            _draw_stem_series!(canvas, prepared, series, plot_width, plot_height, color)
        elseif series isa Scatter
            color = _resolve_series_color(series.color, auto_ix += 1)
            _draw_scatter_series!(canvas, prepared, series, plot_width, plot_height, color)
        elseif series isa Bar
            _draw_bar_series!(canvas, prepared, series, plot_width, plot_height, auto_ix)
            auto_ix += length(series.labels)
        elseif series isa HLine
            color = _resolve_series_color(series.color, auto_ix += 1)
            _draw_hline!(canvas, prepared, series, plot_width, plot_height, color)
        elseif series isa VLine
            color = _resolve_series_color(series.color, auto_ix += 1)
            _draw_vline!(canvas, prepared, series, plot_width, plot_height, color)
        end
    end
    canvas
end

function _draw_line_series!(
    canvas::PlotCanvas,
    prepared::PreparedPanel,
    series::Line,
    plot_width::Int,
    plot_height::Int,
    color::Symbol,
)
    xcontext = prepared.xcontext
    yaxis = series.yside === :right ? prepared.yright : prepared.yleft
    subwidth = plot_width * 2
    subheight = plot_height * 4
    prev = nothing
    for (x_raw, y_raw) in zip(series.x, series.y)
        point = _series_subpoint(xcontext, prepared.xaxis, yaxis, x_raw, y_raw, subwidth, subheight)
        if isnothing(point)
            prev = nothing
            continue
        end
        visible_point = _point_in_bounds(point, subwidth, subheight) ? (round(Int, point[1]), round(Int, point[2])) : nothing
        if !isnothing(prev)
            _draw_line_transition!(canvas, prev, point, series.step, subwidth, subheight, color)
        elseif !isnothing(visible_point)
            _set_subpixel!(canvas, visible_point[1], visible_point[2], color)
        end
        !isnothing(series.marker) && !isnothing(visible_point) && _draw_series_marker!(canvas, visible_point, series.marker, plot_width, plot_height, color)
        prev = point
    end
end

function _draw_stem_series!(
    canvas::PlotCanvas,
    prepared::PreparedPanel,
    series::Stem,
    plot_width::Int,
    plot_height::Int,
    color::Symbol,
)
    xcontext = prepared.xcontext
    yaxis = series.yside === :right ? prepared.yright : prepared.yleft
    subwidth = plot_width * 2
    subheight = plot_height * 4

    for (x_raw, y_raw) in zip(series.x, series.y)
        point = _series_subpoint(xcontext, prepared.xaxis, yaxis, x_raw, y_raw, subwidth, subheight)
        isnothing(point) && continue
        baseline_point = _series_subpoint(xcontext, prepared.xaxis, yaxis, x_raw, series.baseline, subwidth, subheight)
        isnothing(baseline_point) && continue

        _draw_clipped_segment!(canvas, baseline_point[1], baseline_point[2], point[1], point[2], subwidth, subheight, color)
        visible_point = _point_in_bounds(point, subwidth, subheight) ? (round(Int, point[1]), round(Int, point[2])) : nothing
        !isnothing(series.marker) && !isnothing(visible_point) && _draw_series_marker!(canvas, visible_point, series.marker, plot_width, plot_height, color)
    end
end

function _draw_line_transition!(
    canvas::PlotCanvas,
    prev::Tuple{Float64,Float64},
    point::Tuple{Float64,Float64},
    step::Symbol,
    subwidth::Int,
    subheight::Int,
    color::Symbol,
)
    x0 = Float64(prev[1])
    y0 = Float64(prev[2])
    x1 = Float64(point[1])
    y1 = Float64(point[2])
    if step === :linear
        _draw_clipped_segment!(canvas, x0, y0, x1, y1, subwidth, subheight, color)
    elseif step === :post
        _draw_clipped_segment!(canvas, x0, y0, x1, y0, subwidth, subheight, color)
        _draw_clipped_segment!(canvas, x1, y0, x1, y1, subwidth, subheight, color)
    elseif step === :pre
        _draw_clipped_segment!(canvas, x0, y0, x0, y1, subwidth, subheight, color)
        _draw_clipped_segment!(canvas, x0, y1, x1, y1, subwidth, subheight, color)
    else
        xmid = (x0 + x1) / 2
        _draw_clipped_segment!(canvas, x0, y0, xmid, y0, subwidth, subheight, color)
        _draw_clipped_segment!(canvas, xmid, y0, xmid, y1, subwidth, subheight, color)
        _draw_clipped_segment!(canvas, xmid, y1, x1, y1, subwidth, subheight, color)
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

function _draw_clipped_segment!(
    canvas::PlotCanvas,
    x0::Float64,
    y0::Float64,
    x1::Float64,
    y1::Float64,
    subwidth::Int,
    subheight::Int,
    color::Symbol,
)
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
    !isnothing(clipped) && _draw_segment!(canvas, clipped[1], clipped[2], clipped[3], clipped[4], color)
    nothing
end

function _draw_scatter_series!(
    canvas::PlotCanvas,
    prepared::PreparedPanel,
    series::Scatter,
    plot_width::Int,
    plot_height::Int,
    color::Symbol,
)
    xcontext = prepared.xcontext
    yaxis = series.yside === :right ? prepared.yright : prepared.yleft
    for (x_raw, y_raw) in zip(series.x, series.y)
        point = _series_point(xcontext, prepared.xaxis, yaxis, x_raw, y_raw, plot_width * 2, plot_height * 4)
        isnothing(point) && continue
        _draw_series_marker!(canvas, point, series.marker, plot_width, plot_height, color)
    end
end

function _draw_series_marker!(
    canvas::PlotCanvas,
    point::Tuple{Int,Int},
    marker::Char,
    plot_width::Int,
    plot_height::Int,
    color::Symbol,
)
    cell_col = clamp(fld(point[1], 2) + 1, 1, plot_width)
    cell_row = clamp(fld(point[2], 4) + 1, 1, plot_height)
    canvas.overlays[cell_row, cell_col] = marker
    canvas.overlay_colors[cell_row, cell_col] = color
    nothing
end

function _draw_bar_series!(
    canvas::PlotCanvas,
    prepared::PreparedPanel,
    series::Bar,
    plot_width::Int,
    plot_height::Int,
    auto_ix_start::Int,
)
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
            _fill_bar!(
                canvas,
                prepared.xaxis,
                axis,
                x_center - half_width,
                x_center + half_width,
                y_lo,
                y_hi,
                plot_width,
                plot_height,
                color,
            )
            if y >= 0.0
                pos_base += y
            else
                neg_base += y
            end
        end
    end
end

function _draw_hline!(
    canvas::PlotCanvas,
    prepared::PreparedPanel,
    series::HLine,
    plot_width::Int,
    plot_height::Int,
    color::Symbol,
)
    axis = series.yside === :right ? prepared.yright : prepared.yleft
    row = _value_to_suby(series.y, axis, plot_height * 4)
    isnothing(row) && return
    cell_row = clamp(fld(row, 4) + 1, 1, plot_height)
    for cell_col in 1:plot_width
        _set_guide_cell!(canvas, cell_row, cell_col, :horizontal, color)
    end
end

function _draw_vline!(
    canvas::PlotCanvas,
    prepared::PreparedPanel,
    series::VLine,
    plot_width::Int,
    plot_height::Int,
    color::Symbol,
)
    x = _convert_x(series.x, prepared.xcontext)
    isfinite(x) || return
    col = _value_to_subx(x, prepared.xaxis, plot_width * 2)
    isnothing(col) && return
    cell_col = clamp(fld(col, 2) + 1, 1, plot_width)
    for cell_row in 1:plot_height
        _set_guide_cell!(canvas, cell_row, cell_col, :vertical, color)
    end
end

function _fill_bar!(
    canvas::PlotCanvas,
    xaxis::AxisInfo,
    yaxis::AxisInfo,
    x_lo::Float64,
    x_hi::Float64,
    y_lo::Float64,
    y_hi::Float64,
    plot_width::Int,
    plot_height::Int,
    color::Symbol,
)
    xspan = _clipped_subinterval(x_lo, x_hi, xaxis, plot_width * 2, _value_to_subx)
    yspan = _clipped_subinterval(y_lo, y_hi, yaxis, plot_height * 4, _value_to_suby)
    if isnothing(xspan) || isnothing(yspan)
        return
    end
    xmin = clamp(min(xspan[1], xspan[2]), 0, plot_width * 2 - 1)
    xmax = clamp(max(xspan[1], xspan[2]), 0, plot_width * 2 - 1)
    ymin = clamp(min(yspan[1], yspan[2]), 0, plot_height * 4 - 1)
    ymax = clamp(max(yspan[1], yspan[2]), 0, plot_height * 4 - 1)
    for suby in ymin:ymax
        for subx in xmin:xmax
            _set_fill_subpixel!(canvas, subx, suby, color)
        end
    end
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

function _plot_row_string(canvas::PlotCanvas, row::Int, color_enabled::Bool)::String
    io = IOBuffer()
    active = nothing
    for col in axes(canvas.masks, 2)
        ch, color = _plot_cell(canvas, row, col)
        if color_enabled
            active = _write_color_transition!(io, active, color)
        end
        write(io, ch)
    end
    color_enabled && !isnothing(active) && write(io, "\e[0m")
    String(take!(io))
end

function _plot_cell(canvas::PlotCanvas, row::Int, col::Int)::Tuple{Char,Union{Nothing,Symbol}}
    if canvas.overlays[row, col] != '\0'
        return canvas.overlays[row, col], canvas.overlay_colors[row, col]
    elseif canvas.guides[row, col] != '\0'
        return canvas.guides[row, col], canvas.guide_colors[row, col]
    elseif canvas.fills[row, col] != 0x00
        return _bar_fill_char(canvas.fills[row, col]), canvas.fill_colors[row, col]
    end
    mask = canvas.masks[row, col]
    mask == 0x00 ? (' ', nothing) : (Char(0x2800 + mask), canvas.mask_colors[row, col])
end

function _set_fill_subpixel!(canvas::PlotCanvas, subx::Int, suby::Int, color::Symbol)
    cell_row = fld(suby, 4) + 1
    cell_col = fld(subx, 2) + 1
    dot = _braille_dot(mod(subx, 2), mod(suby, 4))
    canvas.fills[cell_row, cell_col] |= UInt8(dot)
    canvas.fill_colors[cell_row, cell_col] = color
    nothing
end

function _set_guide_cell!(canvas::PlotCanvas, row::Int, col::Int, orientation::Symbol, color::Symbol)
    existing = canvas.guides[row, col]
    canvas.guides[row, col] = _merge_guide_char(existing, orientation)
    canvas.guide_colors[row, col] = color
    nothing
end

function _merge_guide_char(existing::Char, orientation::Symbol)::Char
    if orientation === :horizontal
        existing == '\0' && return '─'
        existing == '│' && return '┼'
        return existing
    end
    existing == '\0' && return '│'
    existing == '─' && return '┼'
    existing
end

function _bar_fill_char(mask::UInt8)::Char
    qmask = _quadrant_mask(mask)
    get(QUADRANT_CHARS, qmask, '█')
end

function _quadrant_mask(mask::UInt8)::UInt8
    left_top = (mask & UInt8(0x01 | 0x02)) != 0
    right_top = (mask & UInt8(0x08 | 0x10)) != 0
    left_bottom = (mask & UInt8(0x04 | 0x40)) != 0
    right_bottom = (mask & UInt8(0x20 | 0x80)) != 0
    UInt8(left_top) | (UInt8(right_top) << 1) | (UInt8(left_bottom) << 2) | (UInt8(right_bottom) << 3)
end

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

function _set_subpixel!(canvas::PlotCanvas, subx::Int, suby::Int, color::Symbol)
    cell_row = fld(suby, 4) + 1
    cell_col = fld(subx, 2) + 1
    dot = _braille_dot(mod(subx, 2), mod(suby, 4))
    canvas.masks[cell_row, cell_col] |= UInt8(dot)
    _merge_mask_color!(canvas.mask_color_layers[cell_row, cell_col], UInt8(dot), color)
    canvas.mask_colors[cell_row, cell_col] = _dominant_mask_color(canvas.mask_color_layers[cell_row, cell_col])
    nothing
end

function _merge_mask_color!(layers::Vector{Pair{Symbol,UInt8}}, dot::UInt8, color::Symbol)
    for ix in eachindex(layers)
        if layers[ix].first === color
            layers[ix] = color => (layers[ix].second | dot)
            return nothing
        end
    end
    push!(layers, color => dot)
    nothing
end

function _dominant_mask_color(layers::Vector{Pair{Symbol,UInt8}})::Union{Nothing,Symbol}
    isempty(layers) && return nothing
    best_color = nothing
    best_count = -1
    for layer in layers
        count = count_ones(layer.second)
        if count >= best_count
            best_count = count
            best_color = layer.first
        end
    end
    best_color
end

function _draw_segment!(canvas::PlotCanvas, x0::Float64, y0::Float64, x1::Float64, y1::Float64, color::Symbol)
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
        _set_subpixel!(canvas, x, y, color)
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
end

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
