const FRAME_TOP_LEFT = '┌'
const FRAME_TOP_RIGHT = '┐'
const FRAME_BOTTOM_LEFT = '└'
const FRAME_BOTTOM_RIGHT = '┘'
const FRAME_TOP_SEAM = '┬'
const FRAME_BOTTOM_SEAM = '┴'
const FRAME_HORIZONTAL = '─'
const FRAME_VERTICAL = '│'
const FRAME_LEFT_OUTER_TICK = '┤'
const FRAME_RIGHT_OUTER_TICK = '├'
const FRAME_BOTTOM_TICK = '┬'
const ANSI_BOLD = "\e[1m"
const ANSI_UNBOLD = "\e[22m"

Base.@kwdef struct PanelChrome
    show_title::Bool = true
    show_legend::Bool = true
    show_left_axis::Bool = true
    show_right_axis::Bool = true
    show_top_frame::Bool = true
    show_bottom_frame::Bool = true
    show_left_frame::Bool = true
    show_right_frame::Bool = true
    show_xticks::Bool = true
    show_xlabel::Bool = true
    left_adjacent::Bool = false
    right_adjacent::Bool = false
    top_adjacent::Bool = false
    bottom_adjacent::Bool = false
end

struct LegendItem
    symbol_plain::String
    symbol_styled::String
    label::String
end

function _render_lines(fig::Figure, io::IO)::Vector{String}
    color_enabled = _color_enabled(io)
    total_width = _resolve_terminal_width(io, fig.width)
    header_lines = String[]
    if !isempty(fig.title)
        push!(header_lines, _bold_text(_center_text(fig.title, total_width), color_enabled))
    end
    isempty(fig.placements) && return header_lines

    panel_scans = [_scan_panel(placement.panel) for placement in fig.placements]
    shared_x = fig.linkx ? _combine_shared_x(panel_scans, [placement.panel for placement in fig.placements]) : nothing
    shared_left = fig.linky ? _combine_shared_y(panel_scans, fig.placements, :left) : nothing
    shared_right = fig.linky ? _combine_shared_y(panel_scans, fig.placements, :right) : nothing
    prepared = [_prepare_panel(fig.placements[i].panel, panel_scans[i], shared_x, shared_left, shared_right) for i in eachindex(fig.placements)]
    global_legend = fig.legend && _layout_has_adjacent_seams(fig.layout)
    global_legend && append!(header_lines, _figure_legend_lines(prepared, total_width, color_enabled))

    col_widths = _layout_sizes(total_width, fig.layout.colweights, fig.layout.colseams; min_size=24)
    body_height = max(fig.height - length(header_lines), fig.layout.rows)
    row_heights = _layout_sizes(body_height, fig.layout.rowweights, fig.layout.rowseams; min_size=8)
    body_lines = sum(row_heights) + sum((seam.gap for seam in fig.layout.rowseams); init=0)
    placed_lines = [Tuple{Int,Int,String}[] for _ in 1:body_lines]
    specs = NamedTuple[]

    for (placement, prepared_panel) in zip(fig.placements, prepared)
        block_width = _span_size(col_widths, fig.layout.colseams, placement.cols)
        block_height = _span_size(row_heights, fig.layout.rowseams, placement.rows)
        chrome = _panel_chrome(fig.layout, fig.placements, placement; show_legend=fig.legend && !global_legend)
        x0 = _layout_offset(col_widths, fig.layout.colseams, first(placement.cols))
        y0 = _layout_offset(row_heights, fig.layout.rowseams, first(placement.rows))
        push!(specs, (
            placement=placement,
            prepared=prepared_panel,
            block_width=block_width,
            block_height=block_height,
            chrome=chrome,
            x0=x0,
            y0=y0,
        ))
    end

    alignment = _layout_alignment(fig.layout, specs)

    for spec in specs
        placement = spec.placement
        prepared_panel = spec.prepared
        chrome = spec.chrome
        top_group = fig.layout.rowaligns[first(placement.rows)]
        bottom_group = fig.layout.rowaligns[last(placement.rows)]
        left_group = fig.layout.colaligns[first(placement.cols)]
        right_group = fig.layout.colaligns[last(placement.cols)]
        top_adjacent = _has_adjacent_neighbor(fig.layout, fig.placements, placement, :top)
        bottom_adjacent = _has_adjacent_neighbor(fig.layout, fig.placements, placement, :bottom)
        block = _render_panel_block(
            prepared_panel,
            spec.block_width,
            spec.block_height,
            color_enabled,
            chrome;
            requested_left_width=left_group != 0 && chrome.show_left_axis ? alignment.left_widths[first(placement.cols)] : prepared_panel.left_width,
            requested_right_width=right_group != 0 && chrome.show_right_axis ? alignment.right_widths[last(placement.cols)] : prepared_panel.right_width,
            requested_top_budget=top_group != 0 && !top_adjacent ? alignment.top_budgets[first(placement.rows)] : nothing,
            requested_bottom_budget=bottom_group != 0 && !bottom_adjacent ? alignment.bottom_budgets[last(placement.rows)] : nothing,
        )
        for (line_ix, line) in pairs(block)
            push!(placed_lines[spec.y0 + line_ix - 1], (spec.x0, spec.block_width, line))
        end
    end

    out = copy(header_lines)
    for segments in placed_lines
        push!(out, _compose_styled_line(segments))
    end
    out
end

_layout_has_adjacent_seams(layout::GridLayout) = any(seam -> seam.style === :adjacent, layout.rowseams) || any(seam -> seam.style === :adjacent, layout.colseams)

function _layout_alignment(layout::GridLayout, specs)::NamedTuple
    left_widths = fill(0, layout.cols)
    right_widths = fill(0, layout.cols)
    top_budgets = fill(0, layout.rows)
    bottom_budgets = fill(0, layout.rows)

    for spec in specs
        placement = spec.placement
        prepared = spec.prepared
        chrome = spec.chrome

        if chrome.show_left_axis
            left_widths[first(placement.cols)] = max(left_widths[first(placement.cols)], prepared.left_width)
        end
        if chrome.show_right_axis && prepared.has_right_axis
            right_widths[last(placement.cols)] = max(right_widths[last(placement.cols)], prepared.right_width)
        end

        top_budgets[first(placement.rows)] = max(
            top_budgets[first(placement.rows)],
            _panel_top_budget(prepared, spec.block_width, chrome),
        )
        bottom_budgets[last(placement.rows)] = max(
            bottom_budgets[last(placement.rows)],
            _panel_bottom_budget(prepared.panel, chrome),
        )
    end

    (
        left_widths=_aligned_track_values(left_widths, layout.colaligns),
        right_widths=_aligned_track_values(right_widths, layout.colaligns),
        top_budgets=_aligned_track_values(top_budgets, layout.rowaligns),
        bottom_budgets=_aligned_track_values(bottom_budgets, layout.rowaligns),
    )
end

function _aligned_track_values(values::Vector{Int}, aligns::Vector{Int})::Vector{Int}
    maxima = Dict{Int,Int}()
    for (value, group) in zip(values, aligns)
        group == 0 && continue
        maxima[group] = max(get(maxima, group, 0), value)
    end

    out = copy(values)
    for ix in eachindex(out)
        group = aligns[ix]
        group == 0 && continue
        out[ix] = get(maxima, group, out[ix])
    end
    out
end

function _layout_sizes(total::Int, weights::Vector{Float64}, seams::Vector{GridSeam}; min_size::Int)::Vector{Int}
    n = length(weights)
    usable = max(total - sum((seam.gap for seam in seams); init=0), n)
    baseline = usable >= min_size * n ? min_size : 1
    sizes = fill(baseline, n)
    extra = usable - baseline * n
    if extra > 0
        sizes .+= _proportional_sizes(extra, weights)
    end
    sizes
end

function _proportional_sizes(total::Int, weights::Vector{Float64})::Vector{Int}
    total <= 0 && return fill(0, length(weights))
    raw = total .* weights ./ sum(weights)
    sizes = floor.(Int, raw)
    remainder = total - sum(sizes)
    fractions = raw .- sizes
    order = sortperm(eachindex(weights); by=i -> fractions[i], rev=true)
    for ix in 1:remainder
        sizes[order[mod1(ix, length(order))]] += 1
    end
    sizes
end

function _span_size(sizes::Vector{Int}, seams::Vector{GridSeam}, span::UnitRange{Int})
    size = sum(sizes[span])
    length(span) <= 1 && return size
    size + sum((seams[ix].gap for ix in first(span):(last(span) - 1)); init=0)
end

function _layout_offset(sizes::Vector{Int}, seams::Vector{GridSeam}, start_ix::Int)::Int
    start_ix == 1 && return 1
    1 + sum(sizes[1:(start_ix - 1)]) + sum((seam.gap for seam in seams[1:(start_ix - 1)]); init=0)
end

function _compose_styled_line(segments::Vector{Tuple{Int,Int,String}})::String
    isempty(segments) && return ""
    sorted = sort(segments; by=first)
    io = IOBuffer()
    cursor = 1
    for (x0, width, line) in sorted
        gap = x0 - cursor
        gap > 0 && write(io, " " ^ gap)
        write(io, line)
        cursor = x0 + width
    end
    String(take!(io))
end

function _panel_chrome(
    layout::GridLayout,
    placements::Vector{PanelPlacement},
    placement::PanelPlacement;
    show_legend::Bool,
)::PanelChrome
    left_adjacent = _has_adjacent_neighbor(layout, placements, placement, :left)
    right_adjacent = _has_adjacent_neighbor(layout, placements, placement, :right)
    top_adjacent = _has_adjacent_neighbor(layout, placements, placement, :top)
    bottom_adjacent = _has_adjacent_neighbor(layout, placements, placement, :bottom)
    PanelChrome(
        show_legend=show_legend,
        show_left_axis=!left_adjacent,
        show_right_axis=!right_adjacent,
        show_top_frame=!top_adjacent,
        show_bottom_frame=true,
        show_left_frame=!left_adjacent,
        show_right_frame=true,
        show_xticks=!bottom_adjacent,
        show_xlabel=!bottom_adjacent,
        left_adjacent=left_adjacent,
        right_adjacent=right_adjacent,
        top_adjacent=top_adjacent,
        bottom_adjacent=bottom_adjacent,
    )
end

function _has_adjacent_neighbor(
    layout::GridLayout,
    placements::Vector{PanelPlacement},
    placement::PanelPlacement,
    side::Symbol,
)::Bool
    if side === :left
        seam_ix = first(placement.cols) - 1
        seam_ix >= 1 || return false
        layout.colseams[seam_ix].style === :adjacent || return false
        return any(other -> other !== placement && last(other.cols) == seam_ix && _spans_overlap(other.rows, placement.rows), placements)
    elseif side === :right
        seam_ix = last(placement.cols)
        seam_ix <= length(layout.colseams) || return false
        layout.colseams[seam_ix].style === :adjacent || return false
        return any(other -> other !== placement && first(other.cols) == seam_ix + 1 && _spans_overlap(other.rows, placement.rows), placements)
    elseif side === :top
        seam_ix = first(placement.rows) - 1
        seam_ix >= 1 || return false
        layout.rowseams[seam_ix].style === :adjacent || return false
        return any(other -> other !== placement && last(other.rows) == seam_ix && _spans_overlap(other.cols, placement.cols), placements)
    end
    seam_ix = last(placement.rows)
    seam_ix <= length(layout.rowseams) || return false
    layout.rowseams[seam_ix].style === :adjacent || return false
    any(other -> other !== placement && first(other.rows) == seam_ix + 1 && _spans_overlap(other.cols, placement.cols), placements)
end

function _figure_legend_lines(prepared::Vector{PreparedPanel}, width::Int, color_enabled::Bool)::Vector{String}
    items = LegendItem[]
    for prepared_panel in prepared
        append!(items, _legend_items(prepared_panel))
    end
    _legend_lines(items, width, color_enabled)
end

function _panel_top_lines(
    prepared::PreparedPanel,
    target_width::Int,
    color_enabled::Bool,
    chrome::PanelChrome,
)::Vector{String}
    [_panel_title_lines(prepared, target_width, color_enabled, chrome); _panel_header_lines(prepared, target_width, color_enabled, chrome)]
end

function _panel_title_lines(
    prepared::PreparedPanel,
    target_width::Int,
    color_enabled::Bool,
    chrome::PanelChrome,
)::Vector{String}
    lines = String[]
    if chrome.show_title && !isempty(prepared.panel.title)
        push!(lines, _bold_text(_center_text(prepared.panel.title, target_width), color_enabled))
    end
    lines
end

function _panel_header_lines(
    prepared::PreparedPanel,
    target_width::Int,
    color_enabled::Bool,
    chrome::PanelChrome,
)::Vector{String}
    _legend_and_label_lines(prepared, target_width, color_enabled, chrome)
end

function _panel_top_budget(prepared::PreparedPanel, target_width::Int, chrome::PanelChrome)::Int
    length(_panel_top_lines(prepared, target_width, false, chrome)) + (chrome.show_top_frame ? 1 : 0)
end

function _panel_bottom_budget(panel::Panel, chrome::PanelChrome)::Int
    (chrome.show_bottom_frame ? 1 : 0) +
    (chrome.show_xticks ? 1 : 0) +
    (chrome.show_xlabel && !isempty(panel.xaxis.label) ? 1 : 0)
end

function _render_panel_block(
    prepared::PreparedPanel,
    target_width::Int,
    target_height::Int,
    color_enabled::Bool,
    chrome::PanelChrome,
    ;
    requested_left_width::Union{Nothing,Int}=nothing,
    requested_right_width::Union{Nothing,Int}=nothing,
    requested_top_budget::Union{Nothing,Int}=nothing,
    requested_bottom_budget::Union{Nothing,Int}=nothing,
)::Vector{String}
    panel = prepared.panel
    left_width, right_width = _fit_axis_widths(
        target_width,
        chrome.show_left_axis ? something(requested_left_width, prepared.left_width) : 0,
        chrome.show_right_axis && prepared.has_right_axis ? something(requested_right_width, prepared.right_width) : 0,
        chrome,
    )
    plot_width = max(1, target_width - _left_decoration_width(left_width, chrome) - _right_decoration_width(right_width, chrome))
    top_frame_count = chrome.show_top_frame ? 1 : 0
    bottom_budget = _panel_bottom_budget(panel, chrome)
    title_lines = _panel_title_lines(prepared, target_width, color_enabled, chrome)
    header_lines = _panel_header_lines(prepared, target_width, color_enabled, chrome)
    available_top_lines = max(target_height - bottom_budget - top_frame_count - 1, 0)
    title_lines, header_lines = _fit_panel_top_sections(title_lines, header_lines, available_top_lines)

    top_padding = 0
    bottom_padding = 0
    if !isnothing(requested_top_budget) || !isnothing(requested_bottom_budget)
        actual_top_budget = length(title_lines) + length(header_lines) + top_frame_count
        target_top_budget = something(requested_top_budget, actual_top_budget)
        target_bottom_budget = something(requested_bottom_budget, bottom_budget)
        desired_top_padding = max(target_top_budget - actual_top_budget, 0)
        desired_bottom_padding = max(target_bottom_budget - bottom_budget, 0)
        available_padding = max(target_height - 1 - actual_top_budget - bottom_budget, 0)
        if desired_top_padding + desired_bottom_padding <= available_padding
            top_padding = desired_top_padding
            bottom_padding = desired_bottom_padding
        end
    end

    plot_height = max(1, target_height - length(title_lines) - length(header_lines) - top_padding - top_frame_count - bottom_budget - bottom_padding)

    canvas = _render_plot_canvas(prepared, plot_width, plot_height)
    tick_rows_left = fill("", plot_height)
    tick_rows_right = fill("", plot_height)
    left_tick_rows = _tick_rows(prepared.yleft, plot_height)
    right_tick_rows = _tick_rows(prepared.yright, plot_height)
    for (row, label) in zip(left_tick_rows, prepared.yleft.tick_labels)
        tick_rows_left[row] = label
    end
    for (row, label) in zip(right_tick_rows, prepared.yright.tick_labels)
        tick_rows_right[row] = label
    end

    out = copy(title_lines)
    top_padding > 0 && append!(out, fill(" " ^ target_width, top_padding))
    append!(out, header_lines)
    chrome.show_top_frame && push!(out, _top_border(left_width, plot_width, right_width, chrome))
    for row in 1:plot_height
        left_label = rpad("", left_width)
        if chrome.show_left_axis && !isempty(tick_rows_left[row])
            left_label = lpad(_truncate_text(tick_rows_left[row], left_width), left_width)
        end
        right_label = rpad("", right_width)
        if chrome.show_right_axis && !isempty(tick_rows_right[row])
            right_label = rpad(_truncate_text(tick_rows_right[row], right_width), right_width)
        end
        left_border = chrome.show_left_frame ? (isempty(tick_rows_left[row]) || !chrome.show_left_axis ? FRAME_VERTICAL : FRAME_LEFT_OUTER_TICK) : '\0'
        right_border = chrome.show_right_frame ? (isempty(tick_rows_right[row]) || !chrome.show_right_axis ? FRAME_VERTICAL : FRAME_RIGHT_OUTER_TICK) : '\0'
        push!(
            out,
            string(_left_row_prefix(left_label, left_border, chrome), _plot_row_string(canvas, row, color_enabled), _right_row_suffix(right_border, right_label, chrome)),
        )
    end
    tick_cols, tick_labels = _x_tick_positions(prepared, left_width, plot_width, right_width, chrome)
    chrome.show_bottom_frame && push!(out, _bottom_border(left_width, plot_width, right_width, tick_cols, chrome))
    chrome.show_xticks && push!(out, _x_tick_line(left_width, plot_width, right_width, tick_cols, tick_labels, chrome))
    if chrome.show_xlabel && !isempty(panel.xaxis.label)
        push!(out, _center_text(panel.xaxis.label, target_width))
    end
    bottom_padding > 0 && append!(out, fill(" " ^ target_width, bottom_padding))
    out
end

function _fit_axis_widths(
    target_width::Int,
    requested_left_width::Int,
    requested_right_width::Int,
    chrome::PanelChrome,
)::Tuple{Int,Int}
    left_width = chrome.show_left_axis ? requested_left_width : 0
    right_width = chrome.show_right_axis ? requested_right_width : 0
    available = max(target_width - _left_decoration_width(0, chrome) - _right_decoration_width(0, chrome) - 1, 0)
    if left_width + right_width <= available
        return left_width, right_width
    elseif left_width == 0
        return 0, available
    elseif right_width == 0
        return available, 0
    end
    left = round(Int, available * left_width / (left_width + right_width))
    left = clamp(left, 0, available)
    right = available - left
    left, right
end

_left_decoration_width(left_width::Int, chrome::PanelChrome) = chrome.show_left_axis ? left_width + 2 : (chrome.show_left_frame ? 1 : 0)
_right_decoration_width(right_width::Int, chrome::PanelChrome) = chrome.show_right_axis ? right_width + 2 : (chrome.show_right_frame ? 1 : 0)

function _left_row_prefix(left_label::AbstractString, left_border::Char, chrome::PanelChrome)::String
    if chrome.show_left_axis
        return string(left_label, ' ', left_border)
    elseif chrome.show_left_frame
        return string(left_border)
    end
    ""
end

function _right_row_suffix(right_border::Char, right_label::AbstractString, chrome::PanelChrome)::String
    if chrome.show_right_axis
        return string(right_border, ' ', right_label)
    elseif chrome.show_right_frame
        return string(right_border)
    end
    ""
end

function _fit_top_lines(lines::Vector{String}, available::Int)::Vector{String}
    available <= 0 && return String[]
    length(lines) <= available && return lines
    if available == 1
        return [first(lines)]
    end
    [first(lines); lines[(end - available + 2):end]...]
end

function _fit_panel_top_sections(
    title_lines::Vector{String},
    header_lines::Vector{String},
    available::Int,
)::Tuple{Vector{String},Vector{String}}
    available <= 0 && return String[], String[]
    title_count = length(title_lines)
    header_count = length(header_lines)
    total = title_count + header_count
    total <= available && return title_lines, header_lines

    if title_count == 0
        keep = min(header_count, available)
        return String[], header_lines[(end - keep + 1):end]
    elseif header_count == 0
        keep = min(title_count, available)
        return title_lines[1:keep], String[]
    end

    kept_titles = String[first(title_lines)]
    remaining = available - 1
    if remaining <= 0
        return kept_titles, String[]
    end

    keep_headers = min(header_count, remaining)
    kept_headers = header_lines[(end - keep_headers + 1):end]
    remaining -= keep_headers
    if remaining <= 0
        return kept_titles, kept_headers
    end

    extra_title_count = min(title_count - 1, remaining)
    append!(kept_titles, title_lines[2:(1 + extra_title_count)])
    kept_titles, kept_headers
end

function _legend_and_label_lines(
    prepared::PreparedPanel,
    width::Int,
    color_enabled::Bool,
    chrome::PanelChrome,
)::Vector{String}
    panel = prepared.panel
    left_label = chrome.show_left_axis ? panel.yaxis_left.label : ""
    right_label = chrome.show_right_axis ? panel.yaxis_right.label : ""
    left_slot, center_slot, right_slot = _header_slot_widths(left_label, right_label, width, chrome.show_legend)
    left_lines = _wrap_text(left_label, left_slot)
    right_lines = _wrap_text(right_label, right_slot)
    legend_lines = chrome.show_legend ? _legend_lines(_legend_items(prepared), center_slot, color_enabled) : String[]

    line_count = max(length(left_lines), length(right_lines), length(legend_lines))
    line_count == 0 && return String[]

    left_block = _bottom_align_text_block(left_lines, line_count, left_slot, :left)
    center_block = _bottom_align_styled_block(legend_lines, line_count, center_slot)
    right_block = _bottom_align_text_block(right_lines, line_count, right_slot, :right)

    [string(left_block[i], center_block[i], right_block[i]) for i in 1:line_count]
end

function _header_slot_widths(
    left_label::AbstractString,
    right_label::AbstractString,
    width::Int,
    show_legend::Bool,
)::Tuple{Int,Int,Int}
    left_slot = isempty(left_label) ? 0 : min(textwidth(left_label), max(fld(width, 4), 1))
    right_slot = isempty(right_label) ? 0 : min(textwidth(right_label), max(fld(width, 4), 1))
    min_center = show_legend ? min(max(fld(width, 3), 10), width) : 0
    center_slot = width - left_slot - right_slot

    while show_legend && center_slot < min_center && (left_slot > 1 || right_slot > 1)
        if left_slot >= right_slot && left_slot > 1
            left_slot -= 1
        elseif right_slot > 1
            right_slot -= 1
        else
            break
        end
        center_slot = width - left_slot - right_slot
    end

    left_slot, max(center_slot, 0), right_slot
end

function _bottom_align_text_block(
    lines::Vector{String},
    height::Int,
    width::Int,
    align::Symbol,
)::Vector{String}
    block = fill(" " ^ width, height)
    start = height - length(lines)
    for (ix, line) in enumerate(lines)
        row = start + ix
        block[row] = align === :right ? lpad(line, width) : rpad(line, width)
    end
    block
end

function _bottom_align_styled_block(lines::Vector{String}, height::Int, width::Int)::Vector{String}
    block = fill(" " ^ width, height)
    start = height - length(lines)
    for (ix, line) in enumerate(lines)
        block[start + ix] = line
    end
    block
end

function _wrap_text(text::AbstractString, width::Int)::Vector{String}
    plain = String(text)
    isempty(plain) && return String[]
    width <= 0 && return [plain]
    textwidth(plain) <= width && return [plain]

    words = split(plain)
    isempty(words) && return [plain]
    lines = String[]
    current = ""
    for word in words
        if isempty(current)
            chunks = _wrap_word(word, width)
            append!(lines, chunks[1:max(length(chunks) - 1, 0)])
            current = chunks[end]
            continue
        end

        candidate = string(current, " ", word)
        if textwidth(candidate) <= width
            current = candidate
            continue
        end

        push!(lines, current)
        chunks = _wrap_word(word, width)
        append!(lines, chunks[1:max(length(chunks) - 1, 0)])
        current = chunks[end]
    end

    !isempty(current) && push!(lines, current)
    lines
end

function _wrap_word(word::AbstractString, width::Int)::Vector{String}
    width <= 0 && return [String(word)]
    textwidth(word) <= width && return [String(word)]

    chunks = String[]
    buffer = IOBuffer()
    used = 0
    for ch in word
        chunk = string(ch)
        chunk_width = textwidth(chunk)
        if used > 0 && used + chunk_width > width
            push!(chunks, String(take!(buffer)))
            used = 0
        end
        write(buffer, ch)
        used += chunk_width
    end
    used > 0 && push!(chunks, String(take!(buffer)))
    chunks
end

function _legend_lines(prepared::PreparedPanel, width::Int, color_enabled::Bool)::Vector{String}
    width <= 0 && return String[]
    items = _legend_items(prepared)
    _legend_lines(items, width, color_enabled)
end

function _legend_lines(items::Vector{LegendItem}, width::Int, color_enabled::Bool)::Vector{String}
    width <= 0 && return String[]
    isempty(items) && return String[]
    lines = String[]
    current_plain = 0
    current = IOBuffer()
    for item in items
        item_lines = _legend_item_lines(item, width, color_enabled)
        if length(item_lines) > 1
            current_plain > 0 && push!(lines, _center_styled_text(String(take!(current)), width))
            current_plain = 0
            append!(lines, (_center_styled_text(line, width) for (_, line) in item_lines))
            continue
        end

        plain_width, styled = only(item_lines)
        sep = current_plain == 0 ? 0 : 2
        if current_plain > 0 && current_plain + sep + plain_width > width
            push!(lines, _center_styled_text(String(take!(current)), width))
            current_plain = 0
        end
        if current_plain > 0
            write(current, "  ")
            current_plain += 2
        end
        write(current, styled)
        current_plain += plain_width
    end
    current_plain > 0 && push!(lines, _center_styled_text(String(take!(current)), width))
    lines
end

function _legend_items(prepared::PreparedPanel)
    items = LegendItem[]
    auto_ix = 0
    for series in prepared.panel.series
        if series isa Line
            color = _resolve_series_color(series.color, auto_ix += 1)
            isempty(series.label) && continue
            symbol = isnothing(series.marker) ? "[-]" : string(series.marker, '─')
            push!(items, LegendItem(symbol, _ansi_text(symbol, color), series.label))
        elseif series isa Stem
            color = _resolve_series_color(series.color, auto_ix += 1)
            isempty(series.label) && continue
            symbol = isnothing(series.marker) ? "[|]" : string(series.marker, '│')
            push!(items, LegendItem(symbol, _ansi_text(symbol, color), series.label))
        elseif series isa Scatter
            color = _resolve_series_color(series.color, auto_ix += 1)
            isempty(series.label) && continue
            symbol = string(series.marker)
            push!(items, LegendItem(symbol, _ansi_text(symbol, color), series.label))
        elseif series isa Bar
            for label_ix in eachindex(series.labels)
                auto_ix += 1
                label = series.labels[label_ix]
                isempty(label) && continue
                color = _resolve_series_color(series.colors[label_ix], auto_ix)
                push!(items, LegendItem("[#]", _ansi_text("[#]", color), label))
            end
        elseif series isa HLine || series isa VLine
            label = series.label
            isempty(label) && continue
            auto_ix += 1
            color = _resolve_series_color(series.color, auto_ix)
            push!(items, LegendItem("[=]", _ansi_text("[=]", color), label))
        end
    end
    items
end

function _legend_item_lines(item::LegendItem, width::Int, color_enabled::Bool)::Vector{Tuple{Int,String}}
    width <= 0 && return Tuple{Int,String}[]
    symbol = color_enabled ? item.symbol_styled : item.symbol_plain
    plain = string(item.symbol_plain, " ", item.label)
    textwidth(plain) <= width && return [(textwidth(plain), string(symbol, " ", item.label))]

    symbol_width = textwidth(item.symbol_plain)
    if symbol_width + 1 >= width
        clipped = _truncate_text(plain, width)
        return [(textwidth(clipped), clipped)]
    end

    first_width = width - symbol_width - 1
    first_chunk, remainder = _split_textwidth_prefix(item.label, first_width)
    if isempty(first_chunk)
        clipped = _truncate_text(plain, width)
        return [(textwidth(clipped), clipped)]
    end

    lines = Tuple{Int,String}[(textwidth(item.symbol_plain) + 1 + textwidth(first_chunk), string(symbol, " ", first_chunk))]
    while !isempty(remainder)
        chunk, remainder = _split_textwidth_prefix(remainder, width)
        isempty(chunk) && break
        push!(lines, (textwidth(chunk), chunk))
    end
    lines
end

function _top_border(left_width::Int, plot_width::Int, right_width::Int, chrome::PanelChrome)::String
    left_prefix = chrome.show_left_axis ? string(" " ^ left_width, ' ') : ""
    right_suffix = chrome.show_right_axis ? string(' ', " " ^ right_width) : ""
    left_cap = chrome.left_adjacent ? FRAME_TOP_SEAM : FRAME_TOP_LEFT
    right_cap = chrome.right_adjacent ? FRAME_TOP_SEAM : FRAME_TOP_RIGHT
    string(left_prefix, _horizontal_frame_row(plot_width, chrome, left_cap, right_cap), right_suffix)
end

function _bottom_border(left_width::Int, plot_width::Int, right_width::Int, tick_cols::Vector{Int}, chrome::PanelChrome)::String
    frame_width = plot_width + (chrome.show_left_frame ? 1 : 0) + (chrome.show_right_frame ? 1 : 0)
    chars = fill(FRAME_HORIZONTAL, frame_width)
    plot_offset = chrome.show_left_frame ? 1 : 0
    for col in (chrome.show_xticks ? tick_cols : Int[])
        pos = plot_offset + col
        1 <= pos <= frame_width && (chars[pos] = FRAME_BOTTOM_TICK)
    end
    if !isempty(chars)
        chrome.show_left_frame && (chars[1] = chrome.left_adjacent ? FRAME_BOTTOM_SEAM : FRAME_BOTTOM_LEFT)
        chrome.show_right_frame && (chars[end] = chrome.right_adjacent ? FRAME_BOTTOM_SEAM : FRAME_BOTTOM_RIGHT)
    end
    left_prefix = chrome.show_left_axis ? string(" " ^ left_width, ' ') : ""
    right_suffix = chrome.show_right_axis ? string(' ', " " ^ right_width) : ""
    string(left_prefix, String(chars), right_suffix)
end

function _horizontal_frame_row(plot_width::Int, chrome::PanelChrome, left_cap::Char, right_cap::Char)::String
    frame_width = plot_width + (chrome.show_left_frame ? 1 : 0) + (chrome.show_right_frame ? 1 : 0)
    frame_width <= 0 && return ""
    chars = fill(FRAME_HORIZONTAL, frame_width)
    chrome.show_left_frame && (chars[1] = left_cap)
    chrome.show_right_frame && (chars[end] = right_cap)
    String(chars)
end

function _x_tick_line(
    left_width::Int,
    plot_width::Int,
    right_width::Int,
    tick_cols::Vector{Int},
    tick_labels::Vector{String},
    chrome::PanelChrome,
)::String
    chars = fill(' ', _left_decoration_width(left_width, chrome) + plot_width + _right_decoration_width(right_width, chrome))
    plot_offset = _left_decoration_width(left_width, chrome)
    for (col, label) in zip(tick_cols, tick_labels)
        start = plot_offset + col - fld(textwidth(label), 2)
        start = _tick_label_start(col, label, length(chars), plot_offset)
        for (offset, ch) in enumerate(label)
            pos = start + offset - 1
            pos <= length(chars) && (chars[pos] = ch)
        end
    end
    String(chars)
end

function _x_tick_positions(
    prepared::PreparedPanel,
    left_width::Int,
    plot_width::Int,
    right_width::Int,
    chrome::PanelChrome,
)
    labels = copy(prepared.xaxis.tick_labels)
    max_label_width = max(4, fld(plot_width, max(length(labels), 1)))
    labels = [_truncate_text(label, max_label_width) for label in labels]
    cols = [
        clamp(round(Int, (_normalize_value(tick, prepared.xaxis) * (plot_width - 1))) + 1, 1, plot_width) for
        tick in prepared.xaxis.ticks
    ]
    line_width = _left_decoration_width(left_width, chrome) + plot_width + _right_decoration_width(right_width, chrome)
    plot_offset = _left_decoration_width(left_width, chrome)
    keep = _thin_positions(cols, labels, line_width, plot_offset)
    cols[keep], labels[keep]
end

function _tick_rows(axis::AxisInfo, plot_height::Int)::Vector{Int}
    [
        clamp(round(Int, ((1.0 - _normalize_value(tick, axis)) * (plot_height - 1))) + 1, 1, plot_height) for
        tick in axis.ticks
    ]
end

function _resolve_terminal_width(io::IO, width::Union{Nothing,Int})
    !isnothing(width) && return max(width, 40)
    try
        cols = displaysize(io)[2]
        return max(cols, 40)
    catch
        return 100
    end
end

function _color_enabled(io::IO)::Bool
    get(io, :color, false) && get(ENV, "NO_COLOR", "") == ""
end

function _center_text(text::AbstractString, width::Int)::String
    clipped = _truncate_text(String(text), width)
    pad = max(width - textwidth(clipped), 0)
    left = fld(pad, 2)
    right = pad - left
    string(" " ^ left, clipped, " " ^ right)
end

function _center_styled_text(text::AbstractString, width::Int)::String
    plain = _strip_ansi(text)
    if textwidth(plain) > width
        plain = _truncate_text(plain, width)
        text = plain
    end
    pad = max(width - textwidth(plain), 0)
    left = fld(pad, 2)
    right = pad - left
    string(" " ^ left, text, " " ^ right)
end

function _bold_text(text::AbstractString, enabled::Bool)::String
    enabled || return String(text)
    string(ANSI_BOLD, text, ANSI_UNBOLD)
end

function _truncate_text(text::String, width::Int)::String
    width <= 0 && return ""
    textwidth(text) <= width && return text
    width <= 3 && return _take_textwidth_prefix(text, width)
    string(_take_textwidth_prefix(text, width - 3), "...")
end

function _split_textwidth_prefix(text::AbstractString, width::Int)::Tuple{String,String}
    width <= 0 && return "", String(text)
    prefix = IOBuffer()
    remainder = IOBuffer()
    used = 0
    taking_prefix = true
    for grapheme in Base.Unicode.graphemes(text)
        grapheme_width = textwidth(grapheme)
        if taking_prefix && used + grapheme_width <= width
            write(prefix, grapheme)
            used += grapheme_width
        else
            taking_prefix = false
            write(remainder, grapheme)
        end
    end
    String(take!(prefix)), String(take!(remainder))
end

function _take_textwidth_prefix(text::AbstractString, width::Int)::String
    first(_split_textwidth_prefix(text, width))
end

function _ansi_text(text::AbstractString, color::Symbol)::String
    code = get(ANSI_CODES, color, "")
    isempty(code) && return String(text)
    string(code, text, "\e[0m")
end

function _strip_ansi(text::AbstractString)::String
    replace(String(text), r"\e\[[0-9;]*m" => "")
end
