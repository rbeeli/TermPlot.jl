const FRAME_TOP_LEFT = '┌'
const FRAME_TOP_RIGHT = '┐'
const FRAME_BOTTOM_LEFT = '└'
const FRAME_BOTTOM_RIGHT = '┘'
const FRAME_HORIZONTAL = '─'
const FRAME_VERTICAL = '│'
const FRAME_LEFT_TICK = '├'
const FRAME_RIGHT_TICK = '┤'
const FRAME_BOTTOM_TICK = '┬'
const ANSI_BOLD = "\e[1m"
const ANSI_UNBOLD = "\e[22m"

function _render_lines(fig::Figure, io::IO)::Vector{String}
    color_enabled = _color_enabled(io)
    total_width = _resolve_terminal_width(io, fig.width)
    header_lines = String[]
    if !isempty(fig.title)
        push!(header_lines, _bold_text(_center_text(fig.title, total_width), color_enabled))
    end
    isempty(fig.placements) && return header_lines

    panel_scans = [_scan_panel(placement.panel) for placement in fig.placements]
    shared_x = fig.linkx ? _combine_shared_x(panel_scans) : nothing
    shared_left = fig.linky ? _combine_shared_y(panel_scans, fig.placements, :left) : nothing
    shared_right = fig.linky ? _combine_shared_y(panel_scans, fig.placements, :right) : nothing
    prepared = [_prepare_panel(fig.placements[i].panel, panel_scans[i], shared_x, shared_left, shared_right) for i in eachindex(fig.placements)]

    preferred_left = maximum(pp.left_width for pp in prepared)
    preferred_right = maximum(pp.right_width for pp in prepared)
    col_widths = _layout_sizes(total_width, fig.layout.colweights, fig.layout.colgap; min_size=24)
    body_height = max(fig.height - length(header_lines), fig.layout.rows)
    row_heights = _layout_sizes(body_height, fig.layout.rowweights, fig.layout.rowgap; min_size=8)
    body_lines = sum(row_heights) + fig.layout.rowgap * (fig.layout.rows - 1)
    placed_lines = [Tuple{Int,Int,String}[] for _ in 1:body_lines]

    for (placement, prepared_panel) in zip(fig.placements, prepared)
        block_width = _span_size(col_widths, fig.layout.colgap, placement.cols)
        block_height = _span_size(row_heights, fig.layout.rowgap, placement.rows)
        block = _render_panel_block(
            prepared_panel,
            block_width,
            block_height,
            preferred_left,
            preferred_right,
            color_enabled,
            fig.legend,
        )
        x0 = _layout_offset(col_widths, fig.layout.colgap, first(placement.cols))
        y0 = _layout_offset(row_heights, fig.layout.rowgap, first(placement.rows))
        for (line_ix, line) in pairs(block)
            push!(placed_lines[y0 + line_ix - 1], (x0, block_width, line))
        end
    end

    out = copy(header_lines)
    for segments in placed_lines
        push!(out, _compose_styled_line(segments))
    end
    out
end

function _layout_sizes(total::Int, weights::Vector{Float64}, gap::Int; min_size::Int)::Vector{Int}
    n = length(weights)
    usable = max(total - gap * (n - 1), n)
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

_span_size(sizes::Vector{Int}, gap::Int, span::UnitRange{Int}) = sum(sizes[span]) + gap * (length(span) - 1)

function _layout_offset(sizes::Vector{Int}, gap::Int, start_ix::Int)::Int
    start_ix == 1 && return 1
    1 + sum(sizes[1:(start_ix - 1)]) + gap * (start_ix - 1)
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

function _render_panel_block(
    prepared::PreparedPanel,
    target_width::Int,
    target_height::Int,
    preferred_left_width::Int,
    preferred_right_width::Int,
    color_enabled::Bool,
    show_legend::Bool,
)::Vector{String}
    panel = prepared.panel
    left_width, right_width = _fit_axis_widths(prepared, target_width, preferred_left_width, preferred_right_width)
    plot_width = max(1, target_width - left_width - right_width - 4)
    top_lines = String[]
    if !isempty(panel.title)
        push!(top_lines, _bold_text(_center_text(panel.title, target_width), color_enabled))
    end

    append!(top_lines, _legend_and_label_lines(prepared, target_width, color_enabled, show_legend))

    fixed_lines = 3 + (!isempty(panel.xaxis.label) ? 1 : 0)
    top_lines = _fit_top_lines(top_lines, max(target_height - fixed_lines - 1, 0))
    plot_height = max(1, target_height - length(top_lines) - fixed_lines)

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

    out = copy(top_lines)
    push!(out, _top_border(left_width, plot_width, right_width))
    for row in 1:plot_height
        left_label = rpad("", left_width)
        if !isempty(tick_rows_left[row])
            left_label = lpad(_truncate_text(tick_rows_left[row], left_width), left_width)
        end
        right_label = rpad("", right_width)
        if !isempty(tick_rows_right[row])
            right_label = rpad(_truncate_text(tick_rows_right[row], right_width), right_width)
        end
        left_border = isempty(tick_rows_left[row]) ? FRAME_VERTICAL : FRAME_LEFT_TICK
        right_border = isempty(tick_rows_right[row]) ? FRAME_VERTICAL : FRAME_RIGHT_TICK
        push!(
            out,
            string(
                left_label,
                ' ',
                left_border,
                _plot_row_string(canvas, row, color_enabled),
                right_border,
                ' ',
                right_label,
            ),
        )
    end
    tick_cols, tick_labels = _x_tick_positions(prepared, plot_width)
    push!(out, _bottom_border(left_width, plot_width, right_width, tick_cols))
    push!(out, _x_tick_line(left_width, plot_width, right_width, tick_cols, tick_labels))
    if !isempty(panel.xaxis.label)
        push!(out, _center_text(panel.xaxis.label, target_width))
    end
    out
end

function _fit_axis_widths(
    prepared::PreparedPanel,
    target_width::Int,
    preferred_left_width::Int,
    preferred_right_width::Int,
)::Tuple{Int,Int}
    left_width = min(prepared.left_width, preferred_left_width)
    right_width = prepared.has_right_axis ? min(prepared.right_width, preferred_right_width) : 0
    available = max(target_width - 5, 0)
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

function _fit_top_lines(lines::Vector{String}, available::Int)::Vector{String}
    available <= 0 && return String[]
    length(lines) <= available && return lines
    if available == 1
        return [first(lines)]
    end
    [first(lines); lines[(end - available + 2):end]...]
end

function _legend_and_label_lines(
    prepared::PreparedPanel,
    width::Int,
    color_enabled::Bool,
    show_legend::Bool,
)::Vector{String}
    panel = prepared.panel
    left_label = panel.yaxis_left.label
    right_label = panel.yaxis_right.label
    left_slot, center_slot, right_slot = _header_slot_widths(left_label, right_label, width, show_legend)
    left_lines = _wrap_text(left_label, left_slot)
    right_lines = _wrap_text(right_label, right_slot)
    legend_lines = show_legend ? _legend_lines(prepared, center_slot, color_enabled) : String[]

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
    isempty(items) && return String[]
    lines = String[]
    current_plain = 0
    current = IOBuffer()
    for (plain_width, styled) in items
        sep = current_plain == 0 ? 0 : 2
        if current_plain > 0 && current_plain + sep + plain_width > width
            push!(lines, _center_styled_text(String(take!(current)), width))
            current_plain = 0
        end
        if current_plain > 0
            write(current, "  ")
            current_plain += 2
        end
        write(current, color_enabled ? styled : _strip_ansi(styled))
        current_plain += plain_width
    end
    current_plain > 0 && push!(lines, _center_styled_text(String(take!(current)), width))
    lines
end

function _legend_items(prepared::PreparedPanel)
    items = Tuple{Int,String}[]
    auto_ix = 0
    for series in prepared.panel.series
        if series isa Line
            color = _resolve_series_color(series.color, auto_ix += 1)
            isempty(series.label) && continue
            symbol = isnothing(series.marker) ? "[-]" : string(series.marker, '─')
            plain = "$(symbol) $(series.label)"
            styled = string(_ansi_text(symbol, color), " ", series.label)
            push!(items, (textwidth(plain), styled))
        elseif series isa Scatter
            color = _resolve_series_color(series.color, auto_ix += 1)
            isempty(series.label) && continue
            symbol = string(series.marker)
            plain = "$(symbol) $(series.label)"
            styled = string(_ansi_text(symbol, color), " ", series.label)
            push!(items, (textwidth(plain), styled))
        elseif series isa Bar
            for label_ix in eachindex(series.labels)
                auto_ix += 1
                label = series.labels[label_ix]
                isempty(label) && continue
                color = _resolve_series_color(series.colors[label_ix], auto_ix)
                plain = "[#] $(label)"
                styled = string(_ansi_text("[#]", color), " ", label)
                push!(items, (textwidth(plain), styled))
            end
        elseif series isa HLine || series isa VLine
            label = series.label
            isempty(label) && continue
            auto_ix += 1
            color = _resolve_series_color(series.color, auto_ix)
            plain = "[=] $(label)"
            styled = string(_ansi_text("[=]", color), " ", label)
            push!(items, (textwidth(plain), styled))
        end
    end
    items
end

function _top_border(left_width::Int, plot_width::Int, right_width::Int)::String
    string(
        " " ^ left_width,
        ' ',
        FRAME_TOP_LEFT,
        string(FRAME_HORIZONTAL) ^ plot_width,
        FRAME_TOP_RIGHT,
        ' ',
        " " ^ right_width,
    )
end

function _bottom_border(left_width::Int, plot_width::Int, right_width::Int, tick_cols::Vector{Int})::String
    chars = fill(FRAME_HORIZONTAL, plot_width)
    for col in tick_cols
        1 <= col <= plot_width && (chars[col] = FRAME_BOTTOM_TICK)
    end
    string(
        " " ^ left_width,
        ' ',
        FRAME_BOTTOM_LEFT,
        String(chars),
        FRAME_BOTTOM_RIGHT,
        ' ',
        " " ^ right_width,
    )
end

function _x_tick_line(
    left_width::Int,
    plot_width::Int,
    right_width::Int,
    tick_cols::Vector{Int},
    tick_labels::Vector{String},
)::String
    chars = fill(' ', left_width + plot_width + right_width + 4)
    for (col, label) in zip(tick_cols, tick_labels)
        start = left_width + 2 + col - fld(textwidth(label), 2)
        start = clamp(start, 1, max(length(chars) - textwidth(label) + 1, 1))
        for (offset, ch) in enumerate(label)
            pos = start + offset - 1
            pos <= length(chars) && (chars[pos] = ch)
        end
    end
    String(chars)
end

function _x_tick_positions(prepared::PreparedPanel, plot_width::Int)
    labels = copy(prepared.xaxis.tick_labels)
    max_label_width = max(4, fld(plot_width, max(length(labels), 1)))
    labels = [_truncate_text(label, max_label_width) for label in labels]
    cols = [
        clamp(round(Int, (_normalize_value(tick, prepared.xaxis) * (plot_width - 1))) + 1, 1, plot_width) for
        tick in prepared.xaxis.ticks
    ]
    keep = _thin_positions(cols, labels, plot_width)
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
    textwidth(text) <= width && return text
    width <= 3 && return text[1:width]
    text[1:max(width - 3, 1)] * "..."
end

function _ansi_text(text::AbstractString, color::Symbol)::String
    code = get(ANSI_CODES, color, "")
    isempty(code) && return String(text)
    string(code, text, "\e[0m")
end

function _strip_ansi(text::AbstractString)::String
    replace(String(text), r"\e\[[0-9;]*m" => "")
end
