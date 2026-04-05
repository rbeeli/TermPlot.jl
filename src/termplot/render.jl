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
    rows, cols = size(fig.panels)
    color_enabled = _color_enabled(io)
    total_width = _resolve_terminal_width(io, fig.width)
    panel_spacing = cols > 1 ? 3 : 0
    panel_width = max(24, fld(total_width - panel_spacing * (cols - 1), cols))
    header_lines = String[]
    if !isempty(fig.title)
        push!(header_lines, _bold_text(_center_text(fig.title, total_width), color_enabled))
    end

    panel_scans = [_scan_panel(panel) for panel in fig.panels]
    shared_x = fig.linkx ? _combine_shared_x(panel_scans) : nothing
    shared_left = fig.linky ? _combine_shared_y(panel_scans, fig.panels, :left) : nothing
    shared_right = fig.linky ? _combine_shared_y(panel_scans, fig.panels, :right) : nothing
    prepared = [_prepare_panel(fig.panels[i], panel_scans[i], shared_x, shared_left, shared_right) for i in eachindex(fig.panels)]
    prepared_matrix = reshape(prepared, size(fig.panels))

    left_width = maximum(pp.left_width for pp in prepared)
    right_width = maximum(pp.right_width for pp in prepared)
    plot_width = max(10, panel_width - left_width - right_width - 4)
    title_lines = isempty(fig.title) ? 0 : 1
    panel_height = max(10, fld(fig.height - title_lines - (rows - 1), rows))

    row_blocks = Vector{Vector{String}}()
    for row in 1:rows
        blocks = [
            _render_panel_block(
                prepared_matrix[row, col],
                plot_width,
                panel_height,
                left_width,
                right_width,
                color_enabled,
                fig.legend,
            ) for col in 1:cols
        ]
        row_height = maximum(length(block) for block in blocks)
        padded = [_pad_block(block, row_height, left_width + right_width + plot_width + 4) for block in blocks]
        combined = String[]
        for line_ix in 1:row_height
            push!(combined, join((block[line_ix] for block in padded), " " ^ panel_spacing))
        end
        push!(row_blocks, combined)
    end

    out = copy(header_lines)
    for (ix, block) in enumerate(row_blocks)
        append!(out, block)
        ix < length(row_blocks) && push!(out, "")
    end
    out
end

function _pad_block(block::Vector{String}, height::Int, width::Int)::Vector{String}
    padded = copy(block)
    while length(padded) < height
        push!(padded, " " ^ width)
    end
    padded
end

function _render_panel_block(
    prepared::PreparedPanel,
    plot_width::Int,
    target_height::Int,
    left_width::Int,
    right_width::Int,
    color_enabled::Bool,
    show_legend::Bool,
)::Vector{String}
    panel = prepared.panel
    top_lines = String[]
    if !isempty(panel.title)
        push!(top_lines, _bold_text(_center_text(panel.title, left_width + right_width + plot_width + 4), color_enabled))
    end

    append!(top_lines, _legend_and_label_lines(prepared, plot_width + left_width + right_width + 4, color_enabled, show_legend))

    bottom_fixed = 2 + (!isempty(panel.xaxis.label) ? 1 : 0)
    overhead = length(top_lines) + bottom_fixed
    plot_height = max(4, target_height - overhead)

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
            left_label = lpad(tick_rows_left[row], left_width)
        end
        right_label = rpad("", right_width)
        if !isempty(tick_rows_right[row])
            right_label = rpad(tick_rows_right[row], right_width)
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
        push!(out, _center_text(panel.xaxis.label, left_width + right_width + plot_width + 4))
    end
    out
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
            plain = "[-] $(series.label)"
            styled = string(_ansi_text("[-]", color), " ", series.label)
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
