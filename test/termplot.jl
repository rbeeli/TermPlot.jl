@testsnippet TermPlotSetup begin
    using Dates
    using Test
    using TimeZones
    using TermPlot
end

@testitem "basic line render" setup = [TermPlotSetup] begin
    fig = Figure(; width=72, height=18)
    panel!(fig; title="Basic", xlabel="Date", ylabel="Value", x_date_format=dateformat"yyyy-mm-dd")
    dates = [Date(2024, 1, 1) + Day(i) for i in 0:6]
    line!(fig, dates, collect(1.0:7.0); label="Series", color=:cyan)
    hline!(fig, 4.0; color=:gray, label="Mid")

    text = render(fig)

    @test occursin("Basic", text)
    @test occursin("Value", text)
    @test occursin("Date", text)
    @test occursin("[-] Series", text)
    @test occursin("[=] Mid", text)
    @test occursin("┌", text)
    @test occursin("└", text)
    @test occursin("│", text)
    @test occursin("┬", text)
    @test any(ch -> ch == '⠁' || ch == '⣀' || ch == '⠤' || (UInt32(ch) >= 0x2800 && UInt32(ch) <= 0x28ff), text)
end

@testitem "bare show uses the plotting renderer" setup = [TermPlotSetup] begin
    fig = Figure(; width=60, height=16)
    panel!(fig; title="Shown", xlabel="x", ylabel="y")
    line!(fig, 1:4, [1.0, 2.0, 1.5, 3.0]; label="Series", color=:cyan)

    buffer = IOBuffer()
    show(buffer, fig)
    text = String(take!(buffer))

    @test occursin("Shown", text)
    @test occursin("Series", text)
    @test occursin("┌", text)
    @test !occursin("Figure(", text)
end

@testitem "unicode titles and labels truncate without string indexing errors" setup = [TermPlotSetup] begin
    long = repeat("◆", 50)
    fig = Figure(; width=41, height=14, title=long, legend=false)
    panel!(fig; title=long, xlabel=long, ylabel="y")
    line!(fig, 1:4, [1.0, 2.0, 1.5, 3.0]; color=:cyan)

    text = TermPlot._strip_ansi(render(fig))
    lines = split(text, '\n')

    @test textwidth(lines[1]) == 41
    @test occursin("...", lines[1])
    @test any(line -> occursin("...", line), lines)
    @test all(textwidth(line) == 41 for line in lines)
end

@testitem "step line modes expand segments as expected" setup = [TermPlotSetup] begin
    @test TermPlot._line_segments((0, 0), (4, 4), :linear) == [(0.0, 0.0, 4.0, 4.0)]
    @test TermPlot._line_segments((0, 0), (4, 4), :post) == [(0.0, 0.0, 4.0, 0.0), (4.0, 0.0, 4.0, 4.0)]
    @test TermPlot._line_segments((0, 0), (4, 4), :pre) == [(0.0, 0.0, 0.0, 4.0), (0.0, 4.0, 4.0, 4.0)]
    @test TermPlot._line_segments((0, 0), (4, 4), :mid) == [(0.0, 0.0, 2.0, 0.0), (2.0, 0.0, 2.0, 4.0), (2.0, 4.0, 4.0, 4.0)]
end

@testitem "step line API validates and renders" setup = [TermPlotSetup] begin
    fig = Figure(; width=84, height=18)
    panel!(fig; title="Steps", xlabel="Bucket", ylabel="Exposure")
    x = 1:6
    y = [0.2, 0.5, 0.1, 0.7, 0.6, 0.9]
    line!(fig, x, y; label="Post", color=:cyan, step=:post)
    line!(fig, x, y .- 0.1; label="Mid", color=:yellow, step="mid")
    line!(fig, x, y .- 0.2; label="Pre", color=:magenta, step=:pre)

    text = render(fig)

    @test occursin("Steps", text)
    @test occursin("[-] Post", text)
    @test occursin("[-] Mid", text)
    @test occursin("[-] Pre", text)
    bad = Figure()
    panel!(bad)
    @test_throws ArgumentError line!(bad, [1, 2], [1, 2]; step=:bad)
end

@testitem "yside validation rejects typo symbols and invalid integers" setup = [TermPlotSetup] begin
    fig = Figure(; width=60, height=16)
    panel!(fig; xlabel="x", ylabel="y", ylabel_right="y2")

    @test_throws ArgumentError line!(fig, 1:2, [1.0, 2.0]; yside=:rihgt)
    @test_throws ArgumentError stem!(fig, 1:2, [1.0, 2.0]; yside=3)
    @test_throws ArgumentError scatter!(fig, 1:2, [1.0, 2.0]; yside=:centre)
    @test_throws ArgumentError bar!(fig, ["A"], [1.0]; yside=0)
    @test_throws ArgumentError hline!(fig, 1.0; yside=:wrong)
    @test_throws ArgumentError ylims!(fig, 0.0, 1.0; yside=9)
    @test_throws ArgumentError yscale!(fig, :linear; yside=:bad)
end

@testitem "public geometry setters and bar widths reject invalid values" setup = [TermPlotSetup] begin
    fig = Figure(; width=60, height=16)
    panel!(fig; xlabel="x", ylabel="y")

    @test_throws ArgumentError xlims!(fig, -Inf, Inf)
    @test_throws ArgumentError xlims!(fig, NaN, 1.0)
    @test_throws ArgumentError ylims!(fig, -Inf, Inf)
    @test_throws ArgumentError ylims!(fig, NaN, 1.0)
    @test_throws ArgumentError bar!(fig, ["A"], [1.0]; width=NaN)
    @test_throws ArgumentError bar!(fig, ["A"], [1.0]; width=0.0)
end

@testitem "stem plots render and include the baseline in y limits" setup = [TermPlotSetup] begin
    fig = Figure(; width=84, height=18)
    panel = panel!(fig; title="Stem", xlabel="Bucket", ylabel="Signal")
    stem!(fig, 1:5, [0.25, 0.80, -0.35, 0.55, -0.10]; label="Events", color=:cyan, marker=:diamond)

    scan = TermPlot._scan_panel(panel)
    text = render(fig)

    @test scan.yleft_limits[1] <= 0.0 <= scan.yleft_limits[2]
    @test occursin("Stem", text)
    @test occursin("Events", text)
    @test occursin("◆", text)

    bad = Figure()
    panel!(bad)
    @test_throws ArgumentError stem!(bad, [1, 2], [1, 2]; baseline=Inf)
end

@testitem "stem plots clip vertical segments through y limits" setup = [TermPlotSetup] begin
    fig = Figure(; width=40, height=12, legend=false)
    panel!(fig; xlabel="x", ylabel="y")
    stem!(fig, [1.0], [2.0]; color=:cyan, marker=:diamond)
    ylims!(fig, 0.5, 1.5)

    text = render(fig)

    @test any(ch -> UInt32(ch) >= 0x2800 && UInt32(ch) <= 0x28ff, text)
    @test !occursin("◆", text)
end

@testitem "line clipping keeps segments that enter the visible frame" setup = [TermPlotSetup] begin
    fig = Figure(; width=40, height=12, legend=false)
    panel!(fig; xlabel="x", ylabel="y")
    line!(fig, [0.0, 2.0], [0.0, 2.0]; color=:cyan)
    xlims!(fig, 1.0, 2.0)
    ylims!(fig, 0.0, 2.0)

    lines = split(TermPlot._strip_ansi(render(fig)), '\n')
    braille_lines = filter(line -> any(ch -> UInt32(ch) >= 0x2800 && UInt32(ch) <= 0x28ff, line), lines)

    @test length(braille_lines) >= 2
end

@testitem "line markers render and validate marker inputs" setup = [TermPlotSetup] begin
    fig = Figure(; width=84, height=18)
    panel!(fig; title="Markers", xlabel="x", ylabel="y")
    x = 1:5
    line!(fig, x, [1.0, 2.0, 1.5, 2.5, 2.0]; label="Named", color=:cyan, marker=:diamond)
    line!(fig, x, [0.6, 1.2, 1.0, 1.8, 1.4]; label="Custom", color=:yellow, marker='▲')

    text = render(fig)

    @test occursin("◆─ Named", text)
    @test occursin("▲─ Custom", text)
    @test occursin("◆", text)
    @test occursin("▲", text)
    bad = Figure()
    panel!(bad)
    @test_throws ArgumentError line!(bad, [1, 2], [1, 2]; marker="not a marker")
end

@testitem "datetime formatting" setup = [TermPlotSetup] begin
    fig = Figure(; width=72, height=16)
    panel = panel!(fig; xlabel="Time", ylabel="Value", x_date_format=dateformat"yyyy-mm-dd")
    x = [Date(2024, 1, 1), Date(2024, 1, 3)]
    line!(fig, x, [1.0, 2.0]; label="L")
    xlims!(fig, Date(2024, 1, 1), Date(2024, 1, 3))
    ctx = TermPlot._infer_xcontext(panel)
    labels = TermPlot._format_x_ticks(
        [Float64(Dates.datetime2epochms(DateTime(Date(2024, 1, 1))))],
        ctx,
        panel.xaxis.date_format,
    )
    @test labels == ["2024-01-01"]
    @test occursin("2024-01-01", render(fig))

    zctx = TermPlot.XContext(:zoned, TimeZone("America/New_York"), String[], Dict{String,Float64}())
    zlabels = TermPlot._format_x_ticks(
        [Float64(Dates.datetime2epochms(DateTime(ZonedDateTime(2024, 1, 1, 17, 0, 0, tz"UTC"))))],
        zctx,
        dateformat"yyyy-mm-dd HH:MM",
    )
    @test zlabels == ["2024-01-01 12:00"]
end

@testitem "mixed Date and DateTime x values promote to datetime and render" setup = [TermPlotSetup] begin
    fig = Figure(; width=72, height=16)
    panel = panel!(fig; xlabel="Time", ylabel="Value", x_date_format=dateformat"yyyy-mm-dd HH:MM")
    line!(fig, Any[Date(2024, 1, 1), DateTime(2024, 1, 2, 12)], [1.0, 2.0]; label="Mixed", color=:cyan)

    ctx = TermPlot._infer_xcontext(panel)
    converted_date = TermPlot._convert_x(Date(2024, 1, 1), ctx)
    converted_datetime = TermPlot._convert_x(DateTime(2024, 1, 2, 12), ctx)
    text = render(fig)

    @test ctx.kind == :datetime
    @test converted_date == Float64(Dates.datetime2epochms(DateTime(2024, 1, 1)))
    @test converted_datetime == Float64(Dates.datetime2epochms(DateTime(2024, 1, 2, 12)))
    @test occursin("Mixed", text)
end

@testitem "zoned datetime x values infer timezone and render" setup = [TermPlotSetup] begin
    fig = Figure(; width=72, height=16)
    panel = panel!(fig; xlabel="Time", ylabel="Value", x_date_format=dateformat"yyyy-mm-dd HH:MM")
    x = [
        ZonedDateTime(2024, 1, 1, 9, 30, 0, tz"America/New_York"),
        ZonedDateTime(2024, 1, 1, 16, 0, 0, tz"America/New_York"),
    ]
    line!(fig, x, [1.0, 2.0]; label="Zoned", color=:cyan)

    ctx = TermPlot._infer_xcontext(panel)
    converted = TermPlot._convert_x.(x, Ref(ctx))
    expected = [Float64(Dates.datetime2epochms(DateTime(astimezone(value, TimeZone("UTC"))))) for value in x]
    text = render(fig)

    @test ctx.kind == :zoned
    @test string(ctx.timezone) == "America/New_York"
    @test converted == expected
    @test occursin("Zoned", text)
end

@testitem "stacked categorical bars render" setup = [TermPlotSetup] begin
    fig = Figure(; width=72, height=18)
    panel!(fig; title="Bars", xlabel="Bucket", ylabel="Weight")
    stackedbar!(
        fig,
        ["A", "B", "C"],
        [20.0, 30.0, 10.0],
        [80.0, 70.0, 90.0];
        labels=["Risky", "Cash"],
        colors=[:cyan, :yellow],
        width=0.8,
    )
    text = render(fig)
    @test occursin("Bars", text)
    @test occursin("[#] Risky", text)
    @test occursin("[#] Cash", text)
    @test occursin("A", text)
    @test occursin("B", text)
    @test occursin("C", text)
    @test any(ch -> ch == '█' || ch == '▌' || ch == '▐' || ch == '▄', text)
end

@testitem "stacked bars skip fully clipped stack layers on y" setup = [TermPlotSetup] begin
    fig = Figure(; width=50, height=14, legend=false)
    panel!(fig; xlabel="x", ylabel="y")
    stackedbar!(fig, ["A"], [1.0], [1.0]; labels=["L1", "L2"], colors=[:cyan, :yellow])
    ylims!(fig, 0.0, 0.5)

    text = withenv("NO_COLOR" => nothing) do
        buffer = IOBuffer()
        render!(IOContext(buffer, :color => true), fig)
        String(take!(buffer))
    end

    raw_lines = split(text, '\n')
    plain_lines = TermPlot._strip_ansi.(raw_lines)
    top_row = findfirst(line -> occursin(r"^0\.5\s", line), plain_lines)

    @test !isnothing(top_row)
    @test occursin("\e[36m", raw_lines[top_row])
    @test !occursin("\e[33m", raw_lines[top_row])
end

@testitem "simple categorical bars render" setup = [TermPlotSetup] begin
    fig = Figure(; width=72, height=18)
    panel!(fig; title="Simple Bars", xlabel="Factor", ylabel="Score")
    bar!(fig, ["Value", "Quality", "Momentum", "Carry"], [0.8, 0.6, 0.9, 0.5]; label="Signal", color=:cyan, width=0.8)
    ylims!(fig, 0, 1)
    text = render(fig)
    @test occursin("Simple Bars", text)
    @test occursin("[#] Signal", text)
    @test occursin("Value", text)
    @test occursin("Quality", text)
    @test occursin("Momentum", text)
    @test occursin("Carry", text)
    @test any(ch -> ch == '█' || ch == '▌' || ch == '▐' || ch == '▄', text)
end

@testitem "missing-only bars do not create fake y data or linked y contamination" setup = [TermPlotSetup] begin
    empty_fig = Figure(; width=60, height=14, legend=false)
    empty_panel = panel!(empty_fig; xlabel="x", ylabel="y")
    bar!(empty_fig, ["A", "B"], [missing, missing]; label="Empty", color=:cyan)

    empty_scan = TermPlot._scan_panel(empty_panel)

    @test !empty_scan.has_left_data
    @test empty_scan.yleft_limits == (0.0, 1.0)

    linked = Figure(GridLayout(1, 2); width=84, height=16, linky=true, legend=false)
    left = panel!(linked, 1, 1; xlabel="x", ylabel="y")
    right = panel!(linked, 1, 2; xlabel="x", ylabel="y")
    line!(left, 1:3, [100.0, 150.0, 200.0]; color=:yellow)
    bar!(right, ["A", "B"], [missing, missing]; color=:cyan)

    left_scan = TermPlot._scan_panel(left)
    right_scan = TermPlot._scan_panel(right)
    shared_left = TermPlot._combine_shared_y([left_scan, right_scan], linked.placements, :left)

    @test shared_left == left_scan.yleft_limits
end

@testitem "missing and non-finite values do not error" setup = [TermPlotSetup] begin
    fig = Figure(; width=72, height=18)
    panel!(fig; xlabel="x", ylabel="y")
    line!(fig, 1:6, [1.0, 2.0, NaN, 4.0, Inf, 3.0]; label="gappy")
    scatter!(fig, 1:6, [1.0, missing, 2.0, 3.0, NaN, 2.0]; label="points", marker="hd")
    text = render(fig)
    @test occursin("gappy", text)
    @test occursin("points", text)
end

@testitem "wide tick labels and markers preserve terminal and SVG width" setup = [TermPlotSetup] begin
    bars = Figure(; width=40, height=16, legend=false)
    panel!(bars; xlabel="Bucket", ylabel="Score")
    bar!(bars, ["界", "海"], [0.8, 0.6]; color=:cyan)
    ylims!(bars, 0, 1)

    bar_lines = split(TermPlot._strip_ansi(render(bars)), '\n')
    @test all(textwidth(line) == 40 for line in bar_lines)

    markers = Figure(; width=40, height=16, legend=false)
    panel!(markers; xlabel="Bucket", ylabel="Score")
    line!(markers, 1:4, [1.0, 2.0, 1.5, 3.0]; color=:yellow, marker='🐱')

    marker_text = TermPlot._strip_ansi(render(markers))
    marker_lines = split(marker_text, '\n')
    svg = TermPlot.render_svg(markers)

    @test all(textwidth(line) == 40 for line in marker_lines)
    @test count(==('🐱'), marker_text) >= 1
    @test occursin("width=\"336\"", svg)
end

@testitem "braille cells keep the dominant line color at crossings" setup = [TermPlotSetup] begin
    canvas = TermPlot.PlotCanvas(
        fill(UInt8(0), 1, 1),
        Matrix{Union{Nothing,Symbol}}(undef, 1, 1),
        [Pair{Symbol,UInt8}[] for _ in 1:1, _ in 1:1],
        fill(UInt8(0), 1, 1),
        fill(nothing, 1, 1),
        fill('\0', 1, 1),
        fill(nothing, 1, 1),
        fill("", 1, 1),
        fill(nothing, 1, 1),
    )
    canvas.mask_colors[1, 1] = nothing

    TermPlot._set_subpixel!(canvas, 0, 0, :cyan)
    TermPlot._set_subpixel!(canvas, 1, 0, :cyan)
    TermPlot._set_subpixel!(canvas, 0, 1, :cyan)
    TermPlot._set_subpixel!(canvas, 1, 3, :yellow)

    text = withenv("NO_COLOR" => nothing) do
        TermPlot._plot_row_string(canvas, 1, true)
    end

    @test occursin("\e[36m", text)
    @test !occursin("\e[33m", text)
end

@testitem "braille cell color ties prefer the later series" setup = [TermPlotSetup] begin
    canvas = TermPlot.PlotCanvas(
        fill(UInt8(0), 1, 1),
        Matrix{Union{Nothing,Symbol}}(undef, 1, 1),
        [Pair{Symbol,UInt8}[] for _ in 1:1, _ in 1:1],
        fill(UInt8(0), 1, 1),
        fill(nothing, 1, 1),
        fill('\0', 1, 1),
        fill(nothing, 1, 1),
        fill("", 1, 1),
        fill(nothing, 1, 1),
    )
    canvas.mask_colors[1, 1] = nothing

    TermPlot._set_subpixel!(canvas, 0, 0, :cyan)
    TermPlot._set_subpixel!(canvas, 1, 0, :cyan)
    TermPlot._set_subpixel!(canvas, 0, 1, :yellow)
    TermPlot._set_subpixel!(canvas, 1, 1, :yellow)

    text = withenv("NO_COLOR" => nothing) do
        TermPlot._plot_row_string(canvas, 1, true)
    end

    @test occursin("\e[33m", text)
    @test !occursin("\e[36m", text)
end

@testitem "scatter and vertical reference lines render" setup = [TermPlotSetup] begin
    fig = Figure(; width=84, height=18)
    panel!(fig; title="Signals", xlabel="Date", ylabel="Score", x_date_format=dateformat"yyyy-mm-dd")
    x = [Date(2024, 1, 1) + Day(i) for i in 0:5]
    scatter!(fig, x, [0.1, 0.4, 0.2, 0.7, 0.5, 0.3]; label="Hits", color=:cyan, marker="diamond")
    vline!(fig, Date(2024, 1, 4); label="Rebalance", color=:magenta)
    hline!(fig, 0.0; label="Flat", color=:gray)
    text = render(fig)
    @test occursin("Signals", text)
    @test occursin("◆ Hits", text)
    @test occursin("[=] Rebalance", text)
    @test occursin("[=] Flat", text)
    @test occursin("┼", text)
end

@testitem "dual axis render" setup = [TermPlotSetup] begin
    fig = Figure(; width=84, height=18)
    panel!(fig; title="Dual", xlabel="Date", ylabel="Left", ylabel_right="Right", x_date_format=dateformat"yyyy-mm-dd")
    x = [Date(2024, 1, 1) + Day(i) for i in 0:5]
    line!(fig, x, [1, 2, 3, 4, 5, 6]; label="L", color=:cyan)
    scatter!(fig, x, [10, 9, 8, 7, 6, 5]; label="R", color=:red, yside=:right, marker="hd")
    ylims!(fig, 0, 7)
    ylims!(fig, 0, 10; yside=:right)
    text = render(fig)
    @test occursin("Left", text)
    @test occursin("Right", text)
    @test occursin("◆ R", text)
end

@testitem "y axis tick junctions point outside the plot area" setup = [TermPlotSetup] begin
    fig = Figure(; width=84, height=18, legend=false)
    panel!(fig; xlabel="Date", ylabel="Left", ylabel_right="Right", x_date_format=dateformat"yyyy-mm-dd")
    x = [Date(2024, 1, 1) + Day(i) for i in 0:4]
    line!(fig, x, [1, 2, 3, 4, 5]; color=:cyan)
    line!(fig, x, [10, 11, 12, 13, 14]; color=:yellow, yside=:right)
    ylims!(fig, 1, 5)
    ylims!(fig, 10, 14; yside=:right)

    lines = split(TermPlot._strip_ansi(render(fig)), '\n')
    tick_line = findfirst(line -> occursin(r"^\s*5\s+┤", line) && occursin(r"├\s+14\s*$", line), lines)

    @test !isnothing(tick_line)
    @test !occursin(r"^\s*5\s+├", lines[tick_line])
    @test !occursin(r"┤\s+14\s*$", lines[tick_line])
end

@testitem "linked y ignores empty-side default limits from other panels" setup = [TermPlotSetup] begin
    fig = Figure(GridLayout(1, 2); width=90, height=18, linky=true, legend=false)
    left = panel!(fig, 1, 1; xlabel="x", ylabel="Left")
    right = panel!(fig, 1, 2; xlabel="x", ylabel_right="Right")

    line!(left, 1:3, [100.0, 150.0, 200.0]; color=:cyan)
    line!(right, 1:3, [5.0, 6.0, 7.0]; color=:yellow, yside=:right)

    scan_left = TermPlot._scan_panel(left)
    scan_right = TermPlot._scan_panel(right)
    shared_left = TermPlot._combine_shared_y([scan_left, scan_right], fig.placements, :left)
    shared_right = TermPlot._combine_shared_y([scan_left, scan_right], fig.placements, :right)

    @test scan_left.has_left_data
    @test !scan_right.has_left_data
    @test shared_left == scan_left.yleft_limits
    @test shared_right == scan_right.yright_limits
end

@testitem "linked y rejects mixed scales on the same side regardless of panel order" setup = [TermPlotSetup] begin
    function build_fig(linear_first::Bool)
        fig = Figure(GridLayout(1, 2); width=84, height=16, linky=true, legend=false)
        first = panel!(fig, 1, 1; xlabel="x", ylabel="y")
        second = panel!(fig, 1, 2; xlabel="x", ylabel="y")
        if linear_first
            line!(first, 1:3, [0.0, 1.0, 2.0]; color=:cyan)
            yscale!(second, :log10)
            line!(second, 1:3, [1.0, 10.0, 100.0]; color=:yellow)
        else
            yscale!(first, :log10)
            line!(first, 1:3, [1.0, 10.0, 100.0]; color=:yellow)
            line!(second, 1:3, [0.0, 1.0, 2.0]; color=:cyan)
        end
        fig
    end

    @test_throws ArgumentError("linked y-axes require identical scales on the left side") render(build_fig(true))
    @test_throws ArgumentError("linked y-axes require identical scales on the left side") render(build_fig(false))
end

@testitem "linked categorical x recomputes limits in the merged context" setup = [TermPlotSetup] begin
    fig = Figure(GridLayout(1, 2); width=84, height=16, linkx=true, legend=false)
    left = panel!(fig, 1, 1; xlabel="x", ylabel="y")
    right = panel!(fig, 1, 2; xlabel="x", ylabel="y")

    line!(left, ["A"], [1.0]; color=:cyan, marker=:diamond)
    line!(right, ["B"], [1.0]; color=:yellow, marker=:diamond)

    scans = [TermPlot._scan_panel(left), TermPlot._scan_panel(right)]
    shared = TermPlot._combine_shared_x(scans, [left, right])
    text = TermPlot._strip_ansi(render(fig))

    @test shared.xcontext.kind == :categorical
    @test shared.xcontext.categories == ["A", "B"]
    @test shared.limits[1] < 1.0
    @test shared.limits[2] > 1.5
    @test count(==('◆'), text) == 2
end

@testitem "linked Date and DateTime x axes promote to datetime across panels" setup = [TermPlotSetup] begin
    fig = Figure(GridLayout(1, 2); width=96, height=16, linkx=true, legend=false)
    left = panel!(fig, 1, 1; xlabel="Time", ylabel="y", x_date_format=dateformat"yyyy-mm-dd HH:MM")
    right = panel!(fig, 1, 2; xlabel="Time", ylabel="y", x_date_format=dateformat"yyyy-mm-dd HH:MM")

    line!(left, [Date(2024, 1, 1), Date(2024, 1, 2)], [1.0, 2.0]; color=:cyan, marker=:diamond)
    line!(right, [DateTime(2024, 1, 1, 12), DateTime(2024, 1, 2, 12)], [1.5, 2.5]; color=:yellow, marker=:diamond)

    scans = [TermPlot._scan_panel(left), TermPlot._scan_panel(right)]
    shared = TermPlot._combine_shared_x(scans, [left, right])
    text = TermPlot._strip_ansi(render(fig))

    @test shared.xcontext.kind == :datetime
    @test shared.limits[1] <= Float64(Dates.datetime2epochms(DateTime(Date(2024, 1, 1))))
    @test shared.limits[2] >= Float64(Dates.datetime2epochms(DateTime(2024, 1, 2, 12)))
    @test count(==('◆'), text) == 4
end

@testitem "log scale validation" setup = [TermPlotSetup] begin
    fig = Figure(; width=72, height=18)
    panel!(fig; xlabel="x", ylabel="y")
    yscale!(fig, :log10)
    line!(fig, 1:3, [1.0, 10.0, 100.0]; label="ok")
    @test occursin("1e0", render(fig))

    bad = Figure(; width=72, height=18)
    panel!(bad; xlabel="x", ylabel="y")
    yscale!(bad, :log10)
    line!(bad, 1:3, [1.0, -2.0, 3.0]; label="bad")
    @test_throws ArgumentError render(bad)
end

@testitem "log tick thinning preserves end decades and labels distinguish non-decades" setup = [TermPlotSetup] begin
    @test TermPlot._log_ticks(1.0, 1000.0, 2) == [1.0, 1000.0]
    @test TermPlot._format_y_ticks([1.0, 1000.0], :log10) == ["1e0", "1e3"]
    @test TermPlot._format_y_ticks([200.0, 300.0], :log10) == ["200", "300"]
    @test TermPlot._format_number(200.0, 100.0) == "200"
end

@testitem "grid layout render supports spans and overlap checks" setup = [TermPlotSetup] begin
    fig = Figure(
        GridLayout(
            2,
            3;
            rowweights=[2, 1],
            colweights=[2, 1, 1],
            rowseams=GridSeam(; gap=1),
            colseams=GridSeam(; gap=2),
        );
        width=120,
        height=24,
        linkx=true,
    )
    main = panel!(fig, 1, 1:2; title="Main", xlabel="x", ylabel="y")
    side = panel!(fig, 1:2, 3; title="Side", xlabel="x", ylabel="z")
    lower = panel!(fig, 2, 1:2; title="Lower", xlabel="x", ylabel="spread")

    line!(main, 1:5, [1, 2, 3, 2, 1]; label="A")
    line!(side, 1:5, [10, 9, 8, 7, 6]; label="B")
    line!(lower, 1:5, [0.0, 0.5, -0.2, 0.7, 0.1]; label="C")

    @test fig[1, 1] === main
    @test fig[1, 3] === side
    @test fig[2, 2] === lower
    @test fig[1:2, 3:3] === side
    @test_throws ArgumentError panel!(fig, 1, 2:3; title="Overlap")

    text = render(fig)
    @test occursin("Main", text)
    @test occursin("Side", text)
    @test occursin("Lower", text)
end

@testitem "x tick thinning matches final clamped label placement" setup = [TermPlotSetup] begin
    cols = [1, 8, 15, 22, 29]
    labels = ["1.4", "1.45", "1.5", "1.55", "1.6"]

    keep = TermPlot._thin_positions(cols, labels, 40, 15)
    kept_cols = cols[keep]
    kept_labels = labels[keep]
    starts = [TermPlot._tick_label_start(col, label, 40, 15) for (col, label) in zip(kept_cols, kept_labels)]
    stops = [start + textwidth(label) - 1 for (start, label) in zip(starts, kept_labels)]

    @test length(kept_cols) < length(cols)
    @test all(starts[ix] > stops[ix - 1] for ix in 2:length(starts))
end

@testitem "complex dashboard layout renders mixed seams and spanning side sleeve" setup = [TermPlotSetup] begin
    fig = Figure(
        GridLayout(
            3,
            4;
            rowweights=[2.2, 1.2, 1.0],
            colweights=[2.3, 1.3, 1.0, 1.2],
            rowseams=[GridSeam(:adjacent), GridSeam(; gap=1)],
            colseams=[GridSeam(:adjacent), GridSeam(:adjacent), GridSeam(; gap=2)],
            rowaligns=:all,
            colaligns=[:core, :core, :core, :side],
        );
        title="Asymmetric Dashboard",
        width=128,
        height=30,
        legend=false,
    )

    trend = panel!(fig, 1, 1:3; title="Composite Trend", xlabel="Date", ylabel="Level", x_date_format=dateformat"mm-dd")
    pullback = panel!(fig, 2, 1:2; title="Pullback", xlabel="Date", ylabel="z-score", x_date_format=dateformat"mm-dd")
    carry = panel!(fig, 2, 3; title="Carry", xlabel="Date", ylabel="bps", x_date_format=dateformat"mm-dd")
    breadth = panel!(fig, 3, 1:3; title="Breadth", xlabel="Date", ylabel="Share", x_date_format=dateformat"mm-dd")
    risk = panel!(fig, 1:3, 4; title="Risk Sleeve", xlabel="Bucket", ylabel="Weight")

    x = [Date(2024, 9, 1) + Day(i) for i in 0:11]

    line!(trend, x, [100.0, 101.5, 103.0, 102.4, 104.2, 105.6, 106.1, 107.8, 108.5, 109.1, 110.3, 111.0]; color=:cyan)
    line!(pullback, x, [-1.0, -0.6, -0.2, 0.4, 0.8, 0.3, -0.1, -0.5, -0.2, 0.5, 0.9, 0.6]; color=:yellow)
    hline!(pullback, 0.0; color=:gray)
    line!(carry, x, [8.0, 10.0, 11.0, 9.0, 13.0, 14.0, 12.0, 15.0, 16.0, 14.0, 18.0, 19.0]; color=:magenta)
    bar!(breadth, x, [0.42, 0.48, 0.55, 0.51, 0.63, 0.68, 0.66, 0.72, 0.75, 0.71, 0.79, 0.82]; color=:green, width=0.84)
    stackedbar!(
        risk,
        ["EQ", "Rates", "FX", "Cmdty"],
        [55.0, 20.0, 15.0, 10.0],
        [25.0, 30.0, 35.0, 30.0],
        [20.0, 50.0, 50.0, 60.0];
        labels=["Trend", "Carry", "Defensive"],
        colors=[:cyan, :yellow, :blue],
        width=0.82,
    )
    ylims!(risk, 0, 100)

    @test fig[1, 2] === trend
    @test fig[2, 1] === pullback
    @test fig[2, 3] === carry
    @test fig[3, 2] === breadth
    @test fig[2, 4] === risk

    text = TermPlot._strip_ansi(render(fig))
    lines = split(text, '\n')

    @test occursin("Asymmetric Dashboard", text)
    @test occursin("Composite Trend", text)
    @test occursin("Pullback", text)
    @test occursin("Risk Sleeve", text)
    @test occursin("EQ", text)
    @test occursin("Rates", text)
    @test all(Base.textwidth(line) == 128 for line in lines)
end

@testitem "adjacent seams suppress inner axes and share subplot seams" setup = [TermPlotSetup] begin
    fig = Figure(
        GridLayout(
            2,
            2;
            rowseams=GridSeam(:adjacent),
            colseams=GridSeam(:adjacent),
        );
        width=96,
        height=22,
        linkx=true,
        linky=true,
        legend=false,
    )
    top_left = panel!(fig, 1, 1; title="TL", xlabel="x", ylabel="y")
    top_right = panel!(fig, 1, 2; title="TR", xlabel="x", ylabel="y")
    bottom_left = panel!(fig, 2, 1; title="BL", xlabel="x", ylabel="y")
    bottom_right = panel!(fig, 2, 2; title="BR", xlabel="x", ylabel="y")

    line!(top_left, 1:4, [1.0, 2.0, 1.5, 3.0]; label="A")
    line!(top_right, 1:4, [1.2, 2.1, 1.7, 2.8]; label="B")
    line!(bottom_left, 1:4, [0.2, 0.4, 0.3, 0.5]; label="C")
    line!(bottom_right, 1:4, [0.6, 0.5, 0.8, 0.7]; label="D")

    chrome_tl = TermPlot._panel_chrome(fig.layout, fig.placements, fig.placements[1]; show_legend=false)
    chrome_tr = TermPlot._panel_chrome(fig.layout, fig.placements, fig.placements[2]; show_legend=false)
    chrome_bl = TermPlot._panel_chrome(fig.layout, fig.placements, fig.placements[3]; show_legend=false)

    @test !chrome_tl.show_right_axis
    @test !chrome_tl.show_xticks
    @test !chrome_tr.show_left_axis
    @test !chrome_tr.show_xticks
    @test !chrome_bl.show_top_frame

    text = TermPlot._strip_ansi(render(fig))
    @test occursin("TL", text)
    @test occursin("TR", text)
    @test occursin("BL", text)
    @test occursin("BR", text)
    @test !occursin("\n\n", text)
    @test all(Base.textwidth(line) == 96 for line in split(text, '\n'))
end

@testitem "adjacent row seams stay flush under row alignment when inner header text is absent" setup = [TermPlotSetup] begin
    fig = Figure(
        GridLayout(2, 1; rowseams=GridSeam(:adjacent), rowaligns=:all);
        title="Adjacent Rows",
        width=96,
        height=24,
        linkx=true,
        legend=false,
    )
    top = panel!(fig, 1, 1; title="Exposure", xlabel="Bucket", ylabel="Gross")
    bottom = panel!(fig, 2, 1; xlabel="Bucket")

    x = 1:8
    line!(top, x, [0.5, 0.7, 0.8, 0.6, 0.9, 1.0, 0.95, 1.1]; color=:yellow, marker=:circle)
    line!(bottom, x, [-0.4, -0.1, 0.2, 0.5, 0.1, 0.6, 0.3, 0.7]; color=:cyan, marker=:diamond)
    hline!(bottom, 0.0; color=:gray)

    lines = split(TermPlot._strip_ansi(render(fig)), '\n')
    @test !any(line -> !isempty(line) && all(isspace, line), lines)
end

@testitem "adjacent column seams align headers cleanly under row alignment" setup = [TermPlotSetup] begin
    fig = Figure(
        GridLayout(1, 2; rowaligns=:all, colseams=GridSeam(:adjacent), colaligns=:all);
        title="Adjacent Columns",
        width=108,
        height=20,
        linkx=true,
        linky=true,
        legend=false,
    )
    left = panel!(fig, 1, 1; title="Strategy A", xlabel="Date", ylabel="Normalized", x_date_format=dateformat"mm-dd")
    right = panel!(fig, 1, 2; title="Strategy B", xlabel="Date", ylabel="Normalized", x_date_format=dateformat"mm-dd")

    x1 = [Date(2024, 7, 1) + Day(i) for i in 0:7]
    x2 = [Date(2024, 7, 2) + Day(i) for i in 0:7]
    line!(left, x1, [1.00, 1.02, 1.05, 1.03, 1.07, 1.09, 1.08, 1.11]; color=:cyan)
    line!(right, x2, [0.97, 1.00, 1.01, 1.04, 1.02, 1.05, 1.07, 1.10]; color=:magenta)

    lines = split(TermPlot._strip_ansi(render(fig)), '\n')
    title_line = findfirst(line -> occursin("Strategy A", line) && occursin("Strategy B", line), lines)
    ylabel_line = findfirst(line -> occursin("Normalized", line), lines)
    top_border_line = findfirst(line -> occursin('┌', line) && occursin('┐', line), lines)
    bottom_border_line = findfirst(line -> occursin('└', line) && occursin('┘', line), lines)

    @test !isnothing(title_line)
    @test !isnothing(ylabel_line)
    @test !isnothing(top_border_line)
    @test !isnothing(bottom_border_line)
    @test title_line < ylabel_line
    @test !occursin('┐', lines[ylabel_line])
    @test !occursin('┌', lines[ylabel_line])
    @test occursin('┬', lines[top_border_line])
    @test occursin('┴', lines[bottom_border_line])
end

@testitem "grid layout can align selected plot tracks" setup = [TermPlotSetup] begin
    function render_borders(colaligns)
        fig = Figure(
            GridLayout(1, 3; colseams=GridSeam(; gap=2), rowaligns=:all, colaligns=colaligns);
            width=132,
            height=16,
            legend=false,
        )
        left = panel!(fig, 1, 1; title="Titled", xlabel="x", ylabel="y")
        middle = panel!(fig, 1, 2; xlabel="x", ylabel="y")
        right = panel!(fig, 1, 3; xlabel="x", ylabel="y")

        line!(left, 1:4, [1.0, 2.0, 1.5, 3.0]; color=:cyan)
        line!(middle, 1:4, [0.1, 0.2, 0.15, 0.25]; color=:yellow)
        line!(right, 1:4, [100000.0, 120000.0, 90000.0, 110000.0]; color=:magenta)

        filter(line -> occursin("┌", line), split(TermPlot._strip_ansi(render(fig)), '\n'))
    end

    loose = render_borders(:none)
    selected = render_borders([:pair, :pair, :none])
    aligned = render_borders(:all)
    layout = GridLayout(2, 3; rowaligns=:all, colaligns=[:pair, :pair, :none])

    @test layout.rowaligns == [1, 1]
    @test layout.colaligns == [1, 1, 0]
    @test length(loose) == 1
    @test length(selected) == 1
    @test length(aligned) == 1
    @test count(==('┌'), first(loose)) == 3
    @test first(selected) != first(loose)
    @test first(aligned) != first(selected)
end

@testitem "row-aligned header labels stay anchored to the plot frame" setup = [TermPlotSetup] begin
    fig = Figure(
        GridLayout(1, 3; colseams=GridSeam(; gap=2), rowaligns=:all, colaligns=[:pair, :pair, :none]);
        title="Selective Plot Alignment",
        width=112,
        height=16,
        legend=false,
    )
    left = panel!(fig, 1, 1; title="Titled", xlabel="Bucket", ylabel="Wide Label")
    middle = panel!(fig, 1, 2; xlabel="Bucket", ylabel="y")
    right = panel!(fig, 1, 3; xlabel="Bucket", ylabel="y")

    line!(left, 1:4, [1.0, 2.0, 1.5, 3.0]; color=:cyan)
    line!(middle, 1:4, [0.1, 0.2, 0.15, 0.25]; color=:yellow)
    line!(right, 1:4, [100000.0, 120000.0, 90000.0, 110000.0]; color=:magenta)

    lines = split(TermPlot._strip_ansi(render(fig)), '\n')
    header_line = findfirst(line -> occursin("Label", line) && count(==('y'), line) == 2, lines)

    @test !isnothing(header_line)
    @test header_line < length(lines)
    @test !occursin('┌', lines[header_line])
    @test occursin('┌', lines[header_line + 1])
end

@testitem "color-aware render writes ANSI escapes when color is enabled" setup = [TermPlotSetup] begin
    fig = Figure(; width=72, height=18)
    panel!(fig; title="Color", xlabel="x", ylabel="y")
    line!(fig, 1:4, [1.0, 2.0, 1.5, 3.0]; label="Series", color=:cyan)

    plain_buffer = IOBuffer()
    plain_io = IOContext(plain_buffer, :color => false)
    render!(plain_io, fig)
    plain_text = String(take!(plain_buffer))
    @test !occursin("\e[", plain_text)

    withenv("NO_COLOR" => nothing) do
        color_buffer = IOBuffer()
        color_io = IOContext(color_buffer, :color => true)
        render!(color_io, fig)
        color_text = String(take!(color_buffer))
        @test occursin("\e[", color_text)
    end

    withenv("NO_COLOR" => "1") do
        color_buffer = IOBuffer()
        color_io = IOContext(color_buffer, :color => true)
        render!(color_io, fig)
        color_text = String(take!(color_buffer))
        @test occursin("\e[", color_text)
    end
end

@testitem "svg renderer serializes styled text output with colors" setup = [TermPlotSetup] begin
    fig = Figure(; width=40, height=16, title="T <>&")
    panel!(fig; title="Panel", xlabel="x", ylabel="y")
    line!(fig, 1:4, [1.0, 2.0, 1.5, 3.0]; label="Series", color=:cyan, marker=:diamond)
    hline!(fig, 1.5; label="Ref", color=:gray)

    svg = TermPlot.render_svg(fig)
    themed = TermPlot.render_svg(fig; background_fill="#010203", text_fill="#abcdef")
    buffer = IOBuffer()
    TermPlot.render_svg!(buffer, fig)
    shown = IOBuffer()
    show(shown, MIME"image/svg+xml"(), fig)

    @test occursin("<svg", svg)
    @test occursin("JuliaMono", svg)
    @test occursin("<rect width=\"100%\" height=\"100%\" fill=\"#161618\"/>", svg)
    @test occursin("font-size=\"14\" fill=\"#f4f6f7\"", svg)
    @test occursin("fill=\"#138d90\"", svg)
    @test occursin("font-weight=\"700\"", svg)
    @test occursin("T &lt;&gt;&amp;", svg)
    @test !occursin("\e[", svg)
    @test occursin("<rect width=\"100%\" height=\"100%\" fill=\"#010203\"/>", themed)
    @test occursin("font-size=\"14\" fill=\"#abcdef\"", themed)
    @test !showable(MIME"image/svg+xml"(), fig)
    @test showable(MIME"text/plain"(), fig)
    @test String(take!(buffer)) == svg
    @test String(take!(shown)) == svg
end

@testitem "long legend items wrap within width and styled centering clips" setup = [TermPlotSetup] begin
    fig = Figure(; width=40, height=16)
    panel!(fig; xlabel="x", ylabel="y")
    line!(fig, 1:4, [1.0, 2.0, 1.5, 3.0]; label=repeat("LongLabel", 8), color=:cyan)

    text = withenv("NO_COLOR" => nothing) do
        buffer = IOBuffer()
        render!(IOContext(buffer, :color => true), fig)
        String(take!(buffer))
    end
    lines = split(TermPlot._strip_ansi(text), '\n')
    styled = string(TermPlot._ansi_text("[=]", :cyan), " ", repeat("LongLabel", 8))
    centered = TermPlot._center_styled_text(styled, 40)

    @test all(textwidth(line) == 40 for line in lines)
    @test textwidth(TermPlot._strip_ansi(centered)) == 40
    @test occursin("...", TermPlot._strip_ansi(centered))
end

@testitem "legend shares header lines with wrapped axis labels and titles can be bold" setup = [TermPlotSetup] begin
    fig = Figure(; title="Figure Title", width=72, height=18)
    panel!(
        fig;
        title="Panel Title",
        xlabel="x",
        ylabel="Left axis contribution label",
        ylabel_right="Right axis drawdown label",
    )
    line!(fig, 1:4, [1.0, 2.0, 1.5, 3.0]; label="Series A", color=:cyan)
    line!(fig, 1:4, [0.9, 1.4, 1.2, 1.8]; label="Series B", color=:blue)
    hline!(fig, 1.1; label="Threshold", color=:gray)

    buffer = IOBuffer()
    io = IOContext(buffer, :color => true)
    withenv("NO_COLOR" => nothing) do
        render!(io, fig)
    end
    text = String(take!(buffer))
    lines = split(text, '\n')

    title_ix = findfirst(line -> occursin("Panel Title", line), lines)
    border_ix = findfirst(line -> occursin("┌", TermPlot._strip_ansi(line)), lines)
    @test !isnothing(title_ix)
    @test !isnothing(border_ix)

    header_lines = TermPlot._strip_ansi.(lines[(title_ix + 1):(border_ix - 1)])
    @test length(header_lines) >= 2
    @test any(line -> occursin("Series A", line), header_lines)
    @test any(line -> occursin("Series B", line), header_lines)
    @test any(line -> occursin("Threshold", line), header_lines)
    @test occursin("label", header_lines[end])
    @test occursin("Left axis", join(header_lines, "\n"))
    @test occursin("Right axis", join(header_lines, "\n"))
    @test !occursin("contribution label", join(header_lines[1:(end - 1)], "\n"))
    @test !occursin("drawdown label", join(header_lines[1:(end - 1)], "\n"))

    last_header = header_lines[end]
    @test occursin("contribution label", last_header)
    @test occursin("drawdown label", last_header)

    @test occursin("\e[1m", text)
    @test occursin("\e[22m", text)
end

@testitem "legend can be disabled while axis labels remain" setup = [TermPlotSetup] begin
    fig = Figure(; width=72, height=18, legend=false)
    panel!(fig; title="No Legend", xlabel="x", ylabel="Exposure label", ylabel_right="Risk label")
    line!(fig, 1:4, [1.0, 2.0, 1.5, 3.0]; label="Series", color=:cyan)

    text = TermPlot._strip_ansi(render(fig))

    @test occursin("Exposure label", text)
    @test occursin("Risk label", text)
    @test !occursin("Series", text)
end
