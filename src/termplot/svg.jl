const SVG_DEFAULT_FONT_FAMILY = "\"JuliaMono\", \"Iosevka Term\", \"Cascadia Mono\", \"JetBrains Mono\", \"SFMono-Regular\", Menlo, Consolas, monospace"
const SVG_DEFAULT_BACKGROUND_FILL = "#161618"
const SVG_DEFAULT_TEXT_FILL = "#f4f6f7"

"""
    render_svg(
        fig;
        cell_width=8,
        line_height=16,
        padding=8,
        font_family=SVG_DEFAULT_FONT_FAMILY,
        background_fill=SVG_DEFAULT_BACKGROUND_FILL,
        text_fill=SVG_DEFAULT_TEXT_FILL,
    )

Render a figure to an SVG string.

The SVG renderer reuses TermPlot's text layout and ANSI styling, mapping it to
SVG text spans on a dark background.

# Keywords

- `cell_width`: horizontal size of one terminal cell in SVG user units
- `line_height`: vertical line advance in SVG user units
- `padding`: outer padding around the rendered text block
- `font_family`: monospace SVG font stack
- `background_fill`: SVG fill color for the background rectangle
- `text_fill`: default SVG fill color for unstyled text
"""
function render_svg(
    fig::Figure;
    cell_width::Int=8,
    line_height::Int=16,
    padding::Int=8,
    font_family::AbstractString=SVG_DEFAULT_FONT_FAMILY,
    background_fill::AbstractString=SVG_DEFAULT_BACKGROUND_FILL,
    text_fill::AbstractString=SVG_DEFAULT_TEXT_FILL,
)::String
    buffer = IOBuffer()
    render_svg!(
        buffer,
        fig;
        cell_width,
        line_height,
        padding,
        font_family,
        background_fill,
        text_fill,
    )
    String(take!(buffer))
end

"""
    render_svg!(
        io,
        fig;
        cell_width=8,
        line_height=16,
        padding=8,
        font_family=SVG_DEFAULT_FONT_FAMILY,
        background_fill=SVG_DEFAULT_BACKGROUND_FILL,
        text_fill=SVG_DEFAULT_TEXT_FILL,
    )

Render a figure as SVG to an arbitrary `IO` stream.

# Keywords

- `cell_width`: horizontal size of one terminal cell in SVG user units
- `line_height`: vertical line advance in SVG user units
- `padding`: outer padding around the rendered text block
- `font_family`: monospace SVG font stack
- `background_fill`: SVG fill color for the background rectangle
- `text_fill`: default SVG fill color for unstyled text
"""
function render_svg!(
    io::IO,
    fig::Figure;
    cell_width::Int=8,
    line_height::Int=16,
    padding::Int=8,
    font_family::AbstractString=SVG_DEFAULT_FONT_FAMILY,
    background_fill::AbstractString=SVG_DEFAULT_BACKGROUND_FILL,
    text_fill::AbstractString=SVG_DEFAULT_TEXT_FILL,
)
    cell_width > 0 || throw(ArgumentError("cell_width must be positive"))
    line_height > 0 || throw(ArgumentError("line_height must be positive"))
    padding >= 0 || throw(ArgumentError("padding must be non-negative"))

    lines = _render_lines(fig, IOContext(IOBuffer(), :termplot_color_enabled => true))
    plain_lines = _strip_ansi.(lines)
    cols = maximum(textwidth.(plain_lines); init=0)
    rows = length(lines)
    svg_width = 2 * padding + cols * cell_width
    svg_height = 2 * padding + rows * line_height
    font_size = max(line_height - 2, 1)

    write(
        io,
        "<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\" width=\"$(svg_width)\" height=\"$(svg_height)\" viewBox=\"0 0 $(svg_width) $(svg_height)\">",
    )
    write(
        io,
        "<rect width=\"100%\" height=\"100%\" fill=\"",
        _escape_xml_attr(background_fill),
        "\"/>",
    )
    write(
        io,
        "<text xml:space=\"preserve\" font-family=\"",
        _escape_xml_attr(font_family),
        "\" font-size=\"$(font_size)\" fill=\"",
        _escape_xml_attr(text_fill),
        "\" dominant-baseline=\"hanging\" font-variant-ligatures=\"none\">",
    )

    for (row, line) in pairs(lines)
        y = padding + (row - 1) * line_height
        plain_width = textwidth(plain_lines[row])
        write(io, "<tspan x=\"$(padding)\" y=\"$(y)\"")
        if plain_width > 0
            write(io, " textLength=\"$(plain_width * cell_width)\" lengthAdjust=\"spacingAndGlyphs\"")
        end
        write(io, ">")
        for run in _svg_runs(line)
            _write_svg_run!(io, run)
        end
        write(io, "</tspan>")
    end

    write(io, "</text></svg>")
    nothing
end

function Base.show(io::IO, ::MIME"image/svg+xml", fig::Figure)
    render_svg!(io, fig)
end

function _svg_runs(line::AbstractString)
    runs = NamedTuple{(:text, :fill, :bold),Tuple{String,Union{Nothing,String},Bool}}[]
    buffer = IOBuffer()
    fill = nothing
    bold = false
    index = firstindex(line)
    last = lastindex(line)

    function flush!()
        isempty_buffer = position(buffer) == 0
        isempty_buffer && return
        push!(runs, (text=String(take!(buffer)), fill=fill, bold=bold))
    end

    while index <= last
        if line[index] == '\e'
            next_index = nextind(line, index)
            if next_index <= last && line[next_index] == '['
                code_start = nextind(line, next_index)
                code_end = code_start
                while code_end <= last && line[code_end] != 'm'
                    code_end = nextind(line, code_end)
                end
                if code_end <= last
                    flush!()
                    codes = line[code_start:prevind(line, code_end)]
                    fill, bold = _apply_svg_sgr(codes, fill, bold)
                    index = nextind(line, code_end)
                    continue
                end
            end
        end
        write(buffer, line[index])
        index = nextind(line, index)
    end

    flush!()
    runs
end

function _apply_svg_sgr(codes::AbstractString, fill::Union{Nothing,String}, bold::Bool)
    isempty(codes) && return nothing, false
    next_fill = fill
    next_bold = bold
    for code_str in split(String(codes), ';')
        isempty(code_str) && continue
        code = tryparse(Int, code_str)
        isnothing(code) && continue
        if code == 0
            next_fill = nothing
            next_bold = false
        elseif code == 1
            next_bold = true
        elseif code == 22
            next_bold = false
        elseif code == 39
            next_fill = nothing
        else
            color = _svg_ansi_fill(code)
            isnothing(color) || (next_fill = color)
        end
    end
    next_fill, next_bold
end

function _svg_ansi_fill(code::Int)::Union{Nothing,String}
    code == 30 && return "#111111"
    code == 31 && return "#c0392b"
    code == 32 && return "#1e8449"
    code == 33 && return "#b9770e"
    code == 34 && return "#2e86c1"
    code == 35 && return "#8e44ad"
    code == 36 && return "#138d90"
    code == 37 && return "#f4f6f7"
    code == 90 && return "#7b7d7d"
    nothing
end

function _write_svg_run!(io::IO, run)
    attrs = String[]
    !isnothing(run.fill) && push!(attrs, "fill=\"" * run.fill * "\"")
    run.bold && push!(attrs, "font-weight=\"700\"")
    escaped = _escape_xml_text(run.text)
    if isempty(attrs)
        write(io, escaped)
    else
        write(io, "<tspan ", join(attrs, ' '), ">", escaped, "</tspan>")
    end
    nothing
end

function _escape_xml_text(text::AbstractString)::String
    escaped = replace(String(text), '&' => "&amp;", '<' => "&lt;", '>' => "&gt;")
    replace(escaped, '"' => "&quot;")
end

function _escape_xml_attr(text::AbstractString)::String
    escaped = _escape_xml_text(text)
    replace(escaped, '\'' => "&apos;")
end
