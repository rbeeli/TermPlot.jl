Base.@kwdef mutable struct PanelScanAccumulator
    xvalues::Vector{Float64} = Float64[]
    yleft_values::Vector{Float64} = Float64[]
    yright_values::Vector{Float64} = Float64[]
    has_left_data::Bool = false
    has_right_data::Bool = false
end

function _prepare_panel(
    panel::Panel,
    scan,
    shared_x,
    shared_left,
    shared_right,
)::PreparedPanel
    xcontext = isnothing(shared_x) ? scan.xcontext : shared_x.xcontext
    xlimits = isnothing(shared_x) ? scan.xlimits : shared_x.limits
    xaxis = AxisInfo(xlimits, _x_ticks(panel.xaxis, xcontext, xlimits), String[], panel.xaxis.scale)
    xlabels = _format_x_ticks(xaxis.ticks, xcontext, panel.xaxis.date_format)
    xaxis = AxisInfo(xaxis.limits, xaxis.ticks, xlabels, xaxis.scale)

    left_limits = isnothing(shared_left) ? scan.yleft_limits : shared_left
    right_limits = isnothing(shared_right) ? scan.yright_limits : shared_right
    yleft_ticks = _y_ticks(panel.yaxis_left, left_limits)
    yright_ticks = _y_ticks(panel.yaxis_right, right_limits)
    yleft_labels = _format_y_ticks(yleft_ticks, panel.yaxis_left.scale)
    yright_labels = _format_y_ticks(yright_ticks, panel.yaxis_right.scale)
    yleft = AxisInfo(left_limits, yleft_ticks, yleft_labels, panel.yaxis_left.scale)
    yright = AxisInfo(right_limits, yright_ticks, yright_labels, panel.yaxis_right.scale)
    left_width = max(maximum(textwidth.(yleft.tick_labels); init=0), 1)
    right_width = max(maximum(textwidth.(yright.tick_labels); init=0), 1)
    has_right_axis = scan.has_right_data || !isempty(panel.yaxis_right.label) || !isnothing(panel.yaxis_right.limits)
    if !has_right_axis
        yright = AxisInfo(right_limits, Float64[], String[], panel.yaxis_right.scale)
        right_width = 0
    end

    PreparedPanel(panel, xcontext, xaxis, yleft, yright, left_width, has_right_axis ? right_width : 0, has_right_axis)
end

function _scan_panel(panel::Panel)
    xcontext = _infer_xcontext(panel)
    scan = PanelScanAccumulator()
    for series in panel.series
        _scan_series!(scan, panel, xcontext, series)
    end

    xlimits = _effective_xlimits(panel.xaxis, scan.xvalues, xcontext; pad_fraction=_x_pad_fraction(panel))
    yleft_limits = _effective_limits(panel.yaxis_left, scan.yleft_values; pad_fraction=panel.yaxis_left.scale === :log10 ? 0.0 : 0.05)
    yright_limits = _effective_limits(panel.yaxis_right, scan.yright_values; pad_fraction=panel.yaxis_right.scale === :log10 ? 0.0 : 0.05)
    (
        xcontext=xcontext,
        xlimits=xlimits,
        yleft_limits=yleft_limits,
        yright_limits=yright_limits,
        has_left_data=scan.has_left_data,
        has_right_data=scan.has_right_data,
    )
end

function _combine_shared_x(scans, panels)
    kind = nothing
    for scan in scans
        kind = _merge_x_kind(kind, scan.xcontext.kind)
    end
    xcontext = _shared_xcontext(scans, something(kind, :numeric))
    if xcontext.kind == :categorical
        categories = String[]
        seen = Set{String}()
        for scan in scans, category in scan.xcontext.categories
            if !(category in seen)
                push!(categories, category)
                push!(seen, category)
            end
        end
        xcontext = _categorical_context(categories)
        limits = _combine_limits(
            (
                _effective_xlimits(panel.xaxis, _panel_xvalues(panel, xcontext), xcontext; pad_fraction=_x_pad_fraction(panel)) for
                panel in panels
            );
            scale=:linear,
        )
        return (xcontext=xcontext, limits=limits)
    end
    limits = _combine_limits((scan.xlimits for scan in scans); scale=:linear)
    (xcontext=xcontext, limits=limits)
end

function _shared_xcontext(scans, kind::Symbol)::XContext
    isempty(scans) && return XContext(:numeric, nothing, String[], Dict{String,Float64}())
    if kind == :categorical
        return scans[1].xcontext
    elseif kind == :zoned
        timezone = findfirst(scan -> !isnothing(scan.xcontext.timezone), scans)
        return XContext(:zoned, isnothing(timezone) ? nothing : scans[timezone].xcontext.timezone, String[], Dict{String,Float64}())
    end
    XContext(kind, nothing, String[], Dict{String,Float64}())
end

function _panel_xvalues(panel::Panel, xcontext::XContext)::Vector{Float64}
    xvalues = Float64[]
    for series in panel.series
        _append_series_xvalues!(xvalues, xcontext, series)
    end
    xvalues
end

_series_axis(panel::Panel, yside::Symbol) = yside === :right ? panel.yaxis_right : panel.yaxis_left
_series_axis_values(scan::PanelScanAccumulator, yside::Symbol) = yside === :right ? scan.yright_values : scan.yleft_values

function _mark_series_side!(scan::PanelScanAccumulator, yside::Symbol)
    if yside === :right
        scan.has_right_data = true
    else
        scan.has_left_data = true
    end
    nothing
end

function _scan_series!(scan::PanelScanAccumulator, panel::Panel, xcontext::XContext, series::Union{Line,Scatter})
    yaxis = _series_axis(panel, series.yside)
    axis_values = _series_axis_values(scan, series.yside)
    has_sample = false
    for (x_raw, y_raw) in zip(series.x, series.y)
        x = _convert_x(x_raw, xcontext)
        y = _finite_y(y_raw)
        isfinite(x) || continue
        isfinite(y) || continue
        _check_y_valid(y, yaxis)
        push!(scan.xvalues, x)
        push!(axis_values, y)
        has_sample = true
    end
    has_sample && _mark_series_side!(scan, series.yside)
    nothing
end

function _scan_series!(scan::PanelScanAccumulator, panel::Panel, xcontext::XContext, series::Stem)
    yaxis = _series_axis(panel, series.yside)
    axis_values = _series_axis_values(scan, series.yside)
    has_sample = false
    for (x_raw, y_raw) in zip(series.x, series.y)
        x = _convert_x(x_raw, xcontext)
        y = _finite_y(y_raw)
        isfinite(x) || continue
        isfinite(y) || continue
        _check_y_valid(y, yaxis)
        push!(scan.xvalues, x)
        push!(axis_values, y)
        has_sample = true
    end
    if has_sample
        _check_y_valid(series.baseline, yaxis)
        push!(axis_values, series.baseline)
        _mark_series_side!(scan, series.yside)
    end
    nothing
end

function _scan_series!(scan::PanelScanAccumulator, panel::Panel, xcontext::XContext, series::Bar)
    axis_values = _series_axis_values(scan, series.yside)
    yaxis = _series_axis(panel, series.yside)
    positions = _bar_positions(series, xcontext)
    half_width = _bar_half_width(positions, series.width)
    has_sample = false
    for bar_ix in eachindex(positions)
        x = positions[bar_ix]
        isfinite(x) || continue
        _append_bar_span_xvalues!(scan.xvalues, x, half_width)
        pos_total = 0.0
        neg_total = 0.0
        has_bar_value = false
        for stack in series.ys
            y = _finite_y(stack[bar_ix])
            isfinite(y) || continue
            _check_y_valid(y, yaxis)
            has_bar_value = true
            if y >= 0.0
                pos_total += y
            else
                neg_total += y
            end
        end
        has_bar_value || continue
        push!(axis_values, pos_total)
        push!(axis_values, neg_total)
        has_sample = true
    end
    has_sample && _mark_series_side!(scan, series.yside)
    nothing
end

function _scan_series!(scan::PanelScanAccumulator, panel::Panel, xcontext::XContext, series::HLine)
    axis_values = _series_axis_values(scan, series.yside)
    _check_y_valid(series.y, _series_axis(panel, series.yside))
    push!(axis_values, series.y)
    _mark_series_side!(scan, series.yside)
    nothing
end

function _scan_series!(scan::PanelScanAccumulator, ::Panel, xcontext::XContext, series::VLine)
    x = _convert_x(series.x, xcontext)
    isfinite(x) && push!(scan.xvalues, x)
    nothing
end

_append_series_xvalues!(::Vector{Float64}, ::XContext, ::HLine) = nothing

function _append_series_xvalues!(xvalues::Vector{Float64}, xcontext::XContext, series::Union{Line,Scatter,Stem})
    for (x_raw, y_raw) in zip(series.x, series.y)
        x = _convert_x(x_raw, xcontext)
        y = _finite_y(y_raw)
        isfinite(x) || continue
        isfinite(y) || continue
        push!(xvalues, x)
    end
    nothing
end

function _append_series_xvalues!(xvalues::Vector{Float64}, xcontext::XContext, series::Bar)
    positions = _bar_positions(series, xcontext)
    half_width = _bar_half_width(positions, series.width)
    for x in positions
        isfinite(x) || continue
        _append_bar_span_xvalues!(xvalues, x, half_width)
    end
    nothing
end

function _append_series_xvalues!(xvalues::Vector{Float64}, xcontext::XContext, series::VLine)
    x = _convert_x(series.x, xcontext)
    isfinite(x) && push!(xvalues, x)
    nothing
end

_bar_positions(series::Bar, xcontext::XContext) = [_convert_x(value, xcontext) for value in series.x]

function _append_bar_span_xvalues!(xvalues::Vector{Float64}, x::Float64, half_width::Float64)
    push!(xvalues, x - half_width)
    push!(xvalues, x + half_width)
    nothing
end

function _combine_shared_y(scans, placements, side::Symbol)
    contributor_ixs = Int[]
    for ix in eachindex(scans, placements)
        scan = scans[ix]
        placement = placements[ix]
        axis = _series_axis(placement.panel, side)
        has_data = side === :left ? scan.has_left_data : scan.has_right_data
        if has_data || !isnothing(axis.limits)
            push!(contributor_ixs, ix)
        end
    end
    isempty(contributor_ixs) && return nothing
    scales = unique(_series_axis(placements[ix].panel, side).scale for ix in contributor_ixs)
    length(scales) == 1 || throw(ArgumentError("linked y-axes require identical scales on the $(side) side"))
    scale = only(scales)
    limits = _combine_limits(
        side === :left ? (scans[ix].yleft_limits for ix in contributor_ixs) : (scans[ix].yright_limits for ix in contributor_ixs);
        scale,
    )
    limits
end

function _combine_limits(limits_iter; scale::Symbol=:linear)
    lo = Inf
    hi = -Inf
    for limits in limits_iter
        lo = min(lo, limits[1])
        hi = max(hi, limits[2])
    end
    _expand_degenerate_limits((lo, hi); scale)
end

function _effective_limits(axis::Axis, values::Vector{Float64}; pad_fraction::Float64=0.05)
    if !isnothing(axis.limits)
        lo = Float64(axis.limits[1])
        hi = Float64(axis.limits[2])
        return _expand_degenerate_limits((min(lo, hi), max(lo, hi)); scale=axis.scale)
    end
    if isempty(values)
        defaults = axis.scale === :log10 ? (1.0, 10.0) : (0.0, 1.0)
        return defaults
    end
    lo = minimum(values)
    hi = maximum(values)
    lo, hi = _expand_degenerate_limits((lo, hi); scale=axis.scale)
    if axis.scale === :log10
        return lo, hi
    end
    span = hi - lo
    return lo - span * pad_fraction, hi + span * pad_fraction
end

function _effective_xlimits(
    axis::Axis,
    values::Vector{Float64},
    xcontext::XContext;
    pad_fraction::Float64=0.05,
)
    if !isnothing(axis.limits)
        lo = _convert_x(axis.limits[1], xcontext)
        hi = _convert_x(axis.limits[2], xcontext)
        isfinite(lo) || throw(ArgumentError("x-axis lower limit must be finite"))
        isfinite(hi) || throw(ArgumentError("x-axis upper limit must be finite"))
        return _expand_degenerate_limits((min(lo, hi), max(lo, hi)); scale=axis.scale)
    end
    _effective_limits(axis, values; pad_fraction)
end

function _x_pad_fraction(panel::Panel)::Float64
    any(series -> series isa Bar, panel.series) ? 0.0 : 0.02
end

function _expand_degenerate_limits(limits::Tuple{Float64,Float64}; scale::Symbol=:linear)
    lo, hi = limits
    if scale === :log10
        lo > 0.0 || throw(ArgumentError("log scale requires positive limits"))
        hi > 0.0 || throw(ArgumentError("log scale requires positive limits"))
        if lo == hi
            return lo / 10.0, hi * 10.0
        end
        return lo, hi
    end
    if lo == hi
        pad = lo == 0.0 ? 1.0 : 0.05 * abs(lo)
        return lo - pad, hi + pad
    end
    lo, hi
end

function _x_ticks(axis::Axis, xcontext::XContext, limits::Tuple{Float64,Float64})::Vector{Float64}
    if xcontext.kind == :categorical
        lo, hi = limits
        return [Float64(i) for i in eachindex(xcontext.categories) if lo <= i <= hi]
    end
    _nice_ticks(limits[1], limits[2], axis.tick_count)
end

function _y_ticks(axis::Axis, limits::Tuple{Float64,Float64})::Vector{Float64}
    if axis.scale === :log10
        _log_ticks(limits[1], limits[2], axis.tick_count)
    else
        _nice_ticks(limits[1], limits[2], axis.tick_count)
    end
end

function _format_x_ticks(ticks::Vector{Float64}, xcontext::XContext, format::Union{Nothing,DateFormat})
    if xcontext.kind == :categorical
        return [xcontext.categories[clamp(round(Int, tick), 1, length(xcontext.categories))] for tick in ticks]
    elseif xcontext.kind == :date
        fmt = something(format, dateformat"yyyy-mm-dd")
        return [Dates.format(Date(Dates.epochms2datetime(round(Int, tick))), fmt) for tick in ticks]
    elseif xcontext.kind == :datetime
        fmt = something(format, dateformat"yyyy-mm-dd HH:MM")
        return [Dates.format(Dates.epochms2datetime(round(Int, tick)), fmt) for tick in ticks]
    elseif xcontext.kind == :zoned
        fmt = something(format, dateformat"yyyy-mm-dd HH:MM")
        return [Dates.format(astimezone(ZonedDateTime(Dates.epochms2datetime(round(Int, tick)), UTC_TZ), xcontext.timezone), fmt) for tick in ticks]
    end
    step = length(ticks) >= 2 ? abs(ticks[2] - ticks[1]) : 1.0
    _format_number.(ticks, Ref(step))
end

function _format_y_ticks(ticks::Vector{Float64}, scale::Symbol)
    if scale === :log10
        fallback_step = if length(ticks) >= 2
            minimum(abs.(diff(sort(ticks))))
        elseif isempty(ticks)
            1.0
        else
            max(abs(only(ticks)) * 0.1, eps())
        end
        return [_format_log_tick(tick, fallback_step) for tick in ticks]
    end
    step = length(ticks) >= 2 ? abs(ticks[2] - ticks[1]) : 1.0
    _format_number.(ticks, Ref(step))
end

function _infer_xcontext(panel::Panel)::XContext
    categories = String[]
    category_map = Dict{String,Float64}()
    kind = nothing
    context_timezone = nothing

    function register_kind(value)
        local value_kind = _x_kind(value)
        kind = _merge_x_kind(kind, value_kind)
        if value_kind == :zoned
            context_timezone = isnothing(context_timezone) ? TimeZones.timezone(value) : context_timezone
        elseif value_kind == :categorical
            label = string(value)
            if !haskey(category_map, label)
                push!(categories, label)
                category_map[label] = Float64(length(categories))
            end
        end
    end

    for series in panel.series
        if series isa Line || series isa Scatter || series isa Stem || series isa Bar
            for value in series.x
                ismissing(value) && continue
                register_kind(value)
            end
        elseif series isa VLine
            ismissing(series.x) || register_kind(series.x)
        end
    end

    if !isnothing(panel.xaxis.limits)
        ismissing(panel.xaxis.limits[1]) || register_kind(panel.xaxis.limits[1])
        ismissing(panel.xaxis.limits[2]) || register_kind(panel.xaxis.limits[2])
    end

    if isnothing(kind)
        return XContext(:numeric, nothing, String[], Dict{String,Float64}())
    elseif kind == :categorical
        return _categorical_context(categories)
    end
    XContext(kind, context_timezone, String[], Dict{String,Float64}())
end

_merge_x_kind(current::Nothing, incoming::Symbol) = incoming

function _merge_x_kind(current::Symbol, incoming::Symbol)::Symbol
    current == incoming && return current
    current == :date && incoming == :datetime && return :datetime
    current == :datetime && incoming == :date && return :datetime
    throw(ArgumentError("mixed x-axis types are not supported: $(current) and $(incoming)"))
end

function _categorical_context(categories::Vector{String})::XContext
    category_map = Dict{String,Float64}()
    for (ix, category) in pairs(categories)
        category_map[category] = Float64(ix)
    end
    XContext(:categorical, nothing, copy(categories), category_map)
end

function _x_kind(value)::Symbol
    value isa ZonedDateTime && return :zoned
    value isa Date && return :date
    value isa DateTime && return :datetime
    value isa Real && return :numeric
    (value isa AbstractString || value isa Symbol) && return :categorical
    throw(ArgumentError("unsupported x-axis value type $(typeof(value))"))
end

function _convert_x(value, xcontext::XContext)::Float64
    ismissing(value) && return NaN
    if xcontext.kind == :numeric
        return _finite_y(value)
    elseif xcontext.kind == :date
        datetime = _to_datetime_value(value)
        isnothing(datetime) && return NaN
        return Float64(Dates.datetime2epochms(datetime))
    elseif xcontext.kind == :datetime
        datetime = _to_datetime_value(value)
        isnothing(datetime) && return NaN
        return Float64(Dates.datetime2epochms(datetime))
    elseif xcontext.kind == :zoned
        return Float64(Dates.datetime2epochms(DateTime(astimezone(value, UTC_TZ))))
    elseif xcontext.kind == :categorical
        return get(xcontext.category_map, string(value), NaN)
    end
    NaN
end

_to_datetime_value(value::DateTime) = value
_to_datetime_value(value::Date) = DateTime(value)
_to_datetime_value(::Any) = nothing

function _finite_y(value)::Float64
    ismissing(value) && return NaN
    value isa Real || return NaN
    x = Float64(value)
    isfinite(x) ? x : NaN
end

function _check_y_valid(y::Float64, axis::Axis)
    axis.scale === :log10 && y <= 0.0 && throw(ArgumentError("log scale requires positive finite y-values"))
    nothing
end

function _series_point(
    xcontext::XContext,
    xaxis::AxisInfo,
    yaxis::AxisInfo,
    x_raw,
    y_raw,
    subwidth::Int,
    subheight::Int,
)
    point = _series_subpoint(xcontext, xaxis, yaxis, x_raw, y_raw, subwidth, subheight)
    isnothing(point) && return nothing
    _point_in_bounds(point, subwidth, subheight) || return nothing
    round(Int, point[1]), round(Int, point[2])
end

function _series_subpoint(
    xcontext::XContext,
    xaxis::AxisInfo,
    yaxis::AxisInfo,
    x_raw,
    y_raw,
    subwidth::Int,
    subheight::Int,
)
    x = _convert_x(x_raw, xcontext)
    y = _finite_y(y_raw)
    isfinite(x) || return nothing
    isfinite(y) || return nothing
    subx = _value_to_subx_unclipped(x, xaxis, subwidth)
    suby = _value_to_suby_unclipped(y, yaxis, subheight)
    subx, suby
end

function _value_to_subx(x::Float64, axis::AxisInfo, subwidth::Int)
    norm = _normalize_value(x, axis)
    0.0 <= norm <= 1.0 || return nothing
    clamp(round(Int, norm * (subwidth - 1)), 0, subwidth - 1)
end

function _value_to_suby(y::Float64, axis::AxisInfo, subheight::Int)
    norm = _normalize_value(y, axis)
    0.0 <= norm <= 1.0 || return nothing
    clamp(round(Int, (1.0 - norm) * (subheight - 1)), 0, subheight - 1)
end

function _value_to_subx_unclipped(x::Float64, axis::AxisInfo, subwidth::Int)::Float64
    _normalize_value(x, axis) * (subwidth - 1)
end

function _value_to_suby_unclipped(y::Float64, axis::AxisInfo, subheight::Int)::Float64
    (1.0 - _normalize_value(y, axis)) * (subheight - 1)
end

function _point_in_bounds(point::Tuple{Float64,Float64}, subwidth::Int, subheight::Int)::Bool
    0.0 <= point[1] <= subwidth - 1 && 0.0 <= point[2] <= subheight - 1
end

function _normalize_value(value::Float64, axis::AxisInfo)::Float64
    lo, hi = axis.limits
    if axis.scale === :log10
        return (log10(value) - log10(lo)) / (log10(hi) - log10(lo))
    end
    (value - lo) / (hi - lo)
end

function _bar_half_width(positions::Vector{Float64}, width::Float64)::Float64
    finite_positions = sort(filter(isfinite, positions))
    if length(finite_positions) <= 1
        return 0.5 * max(width, 0.1)
    end
    gaps = diff(finite_positions)
    positive_gaps = filter(>(0.0), gaps)
    step = isempty(positive_gaps) ? 1.0 : minimum(positive_gaps)
    0.5 * width * step
end

function _nice_ticks(lo::Float64, hi::Float64, approx::Int)::Vector{Float64}
    lo == hi && return [lo]
    step = _nice_step((hi - lo) / max(approx - 1, 1))
    start = ceil(lo / step) * step
    ticks = Float64[]
    value = start
    while value <= hi + step * 0.5
        push!(ticks, round(value / step) * step)
        value += step
    end
    isempty(ticks) && push!(ticks, lo, hi)
    unique!(ticks)
    ticks
end

function _nice_step(raw::Float64)::Float64
    raw = abs(raw)
    raw == 0.0 && return 1.0
    power = 10.0 ^ floor(log10(raw))
    scaled = raw / power
    step = scaled <= 1.0 ? 1.0 : scaled <= 2.0 ? 2.0 : scaled <= 5.0 ? 5.0 : 10.0
    step * power
end

function _log_ticks(lo::Float64, hi::Float64, approx::Int)::Vector{Float64}
    lo > 0.0 || throw(ArgumentError("log scale requires positive lower limit"))
    hi > 0.0 || throw(ArgumentError("log scale requires positive upper limit"))
    pmin = floor(Int, log10(lo))
    pmax = ceil(Int, log10(hi))
    ticks = [10.0 ^ p for p in pmin:pmax if lo <= 10.0 ^ p <= hi]
    isempty(ticks) && return [lo, hi]
    if length(ticks) <= approx
        return ticks
    end
    ticks[_thin_ticks_preserve_ends(length(ticks), approx)]
end

function _thin_ticks_preserve_ends(count::Int, approx::Int)::Vector{Int}
    keep = clamp(approx, 1, count)
    keep == count && return collect(1:count)
    keep == 1 && return [1]

    idxs = unique(clamp.(round.(Int, range(1, count; length=keep)), 1, count))
    idxs[1] = 1
    idxs[end] = count
    sort!(idxs)
    if length(idxs) < keep
        for candidate in 2:(count - 1)
            candidate in idxs && continue
            push!(idxs, candidate)
            length(idxs) == keep && break
        end
        sort!(idxs)
    end
    idxs
end

function _format_log_tick(tick::Float64, fallback_step::Float64)::String
    exponent = round(Int, log10(tick))
    decade = 10.0 ^ exponent
    if isapprox(tick, decade; rtol=1.0e-10, atol=0.0)
        return "1e$(exponent)"
    end
    _format_number(tick, fallback_step)
end

function _format_number(value::Float64, step::Float64)::String
    if value == 0.0
        return "0"
    end
    abs_value = abs(value)
    if abs_value >= 1.0e6 || abs_value < 1.0e-4
        return @sprintf("%.2e", value)
    end
    decimals = clamp(Int(ceil(-log10(max(step, eps())))) + 1, 0, 6)
    formatted = @sprintf("%.*f", decimals, value)
    if occursin('.', formatted)
        formatted = replace(formatted, r"0+$" => "")
        formatted = replace(formatted, r"\.$" => "")
    end
    formatted
end

function _thin_positions(cols::Vector{Int}, labels::Vector{String}, line_width::Int, plot_offset::Int)::Vector{Bool}
    isempty(cols) && return Bool[]
    for step in 1:length(cols)
        keep = falses(length(cols))
        idxs = collect(1:step:length(cols))
        last(idxs) != length(cols) && push!(idxs, length(cols))
        keep[idxs] .= true
        _positions_fit(cols[keep], labels[keep], line_width, plot_offset) && return keep
    end
    keep = falses(length(cols))
    keep[1] = true
    keep[end] = true
    keep
end

function _positions_fit(cols::Vector{Int}, labels::Vector{String}, line_width::Int, plot_offset::Int)::Bool
    last_end = 0
    for (col, label) in zip(cols, labels)
        start = _tick_label_start(col, label, line_width, plot_offset)
        stop = start + textwidth(label) - 1
        start <= last_end && return false
        last_end = stop
    end
    true
end

function _tick_label_start(col::Int, label::AbstractString, line_width::Int, plot_offset::Int)::Int
    start = plot_offset + col - fld(textwidth(label), 2)
    clamp(start, 1, max(line_width - textwidth(label) + 1, 1))
end
