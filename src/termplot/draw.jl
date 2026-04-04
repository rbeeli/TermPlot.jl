function _render_plot_canvas(prepared::PreparedPanel, plot_width::Int, plot_height::Int)::PlotCanvas
    masks = fill(UInt8(0), plot_height, plot_width)
    mask_colors = fill(nothing, plot_height, plot_width)
    overlays = fill('\0', plot_height, plot_width)
    overlay_colors = fill(nothing, plot_height, plot_width)
    canvas = PlotCanvas(masks, mask_colors, overlays, overlay_colors)

    auto_ix = 0
    for series in prepared.panel.series
        if series isa Line
            color = _resolve_series_color(series.color, auto_ix += 1)
            _draw_line_series!(canvas, prepared, series, plot_width, plot_height, color)
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
        point = _series_point(xcontext, prepared.xaxis, yaxis, x_raw, y_raw, subwidth, subheight)
        if isnothing(point)
            prev = nothing
            continue
        end
        if !isnothing(prev)
            clipped = _clip_line(
                Float64(prev[1]),
                Float64(prev[2]),
                Float64(point[1]),
                Float64(point[2]),
                0.0,
                Float64(subwidth - 1),
                0.0,
                Float64(subheight - 1),
            )
            !isnothing(clipped) && _draw_segment!(canvas, clipped[1], clipped[2], clipped[3], clipped[4], color)
        else
            _set_subpixel!(canvas, point[1], point[2], color)
        end
        prev = point
    end
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
        cell_col = clamp(fld(point[1], 2) + 1, 1, plot_width)
        cell_row = clamp(fld(point[2], 4) + 1, 1, plot_height)
        canvas.overlays[cell_row, cell_col] = series.marker
        canvas.overlay_colors[cell_row, cell_col] = color
    end
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
    _draw_segment!(canvas, 0.0, Float64(row), Float64(plot_width * 2 - 1), Float64(row), color)
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
    _draw_segment!(canvas, Float64(col), 0.0, Float64(col), Float64(plot_height * 4 - 1), color)
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
    left = _value_to_subx(x_lo, xaxis, plot_width * 2)
    right = _value_to_subx(x_hi, xaxis, plot_width * 2)
    lo = _value_to_suby(y_lo, yaxis, plot_height * 4)
    hi = _value_to_suby(y_hi, yaxis, plot_height * 4)
    if isnothing(left) && isnothing(right)
        return
    end
    left = something(left, x_lo < xaxis.limits[1] ? 0 : plot_width * 2 - 1)
    right = something(right, x_hi < xaxis.limits[1] ? 0 : plot_width * 2 - 1)
    lo = something(lo, y_lo < yaxis.limits[1] ? plot_height * 4 - 1 : 0)
    hi = something(hi, y_hi < yaxis.limits[1] ? plot_height * 4 - 1 : 0)
    xmin = clamp(min(left, right), 0, plot_width * 2 - 1)
    xmax = clamp(max(left, right), 0, plot_width * 2 - 1)
    ymin = clamp(min(lo, hi), 0, plot_height * 4 - 1)
    ymax = clamp(max(lo, hi), 0, plot_height * 4 - 1)
    for suby in ymin:ymax
        for subx in xmin:xmax
            _set_subpixel!(canvas, subx, suby, color)
        end
    end
end

function _plot_row_string(canvas::PlotCanvas, row::Int, color_enabled::Bool)::String
    io = IOBuffer()
    active = nothing
    for col in axes(canvas.masks, 2)
        ch, color = if canvas.overlays[row, col] != '\0'
            (canvas.overlays[row, col], canvas.overlay_colors[row, col])
        else
            mask = canvas.masks[row, col]
            (mask == 0x00 ? ' ' : Char(0x2800 + mask), canvas.mask_colors[row, col])
        end
        if color_enabled
            active = _write_color_transition!(io, active, color)
        end
        write(io, ch)
    end
    color_enabled && !isnothing(active) && write(io, "\e[0m")
    String(take!(io))
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

function _set_subpixel!(canvas::PlotCanvas, subx::Int, suby::Int, color::Symbol)
    cell_row = fld(suby, 4) + 1
    cell_col = fld(subx, 2) + 1
    dot = _braille_dot(mod(subx, 2), mod(suby, 4))
    canvas.masks[cell_row, cell_col] |= UInt8(dot)
    canvas.mask_colors[cell_row, cell_col] = color
    nothing
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
