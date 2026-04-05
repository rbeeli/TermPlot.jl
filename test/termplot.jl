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

@testitem "missing and non-finite values do not error" setup = [TermPlotSetup] begin
    fig = Figure(; width=72, height=18)
    panel!(fig; xlabel="x", ylabel="y")
    line!(fig, 1:6, [1.0, 2.0, NaN, 4.0, Inf, 3.0]; label="gappy")
    scatter!(fig, 1:6, [1.0, missing, 2.0, 3.0, NaN, 2.0]; label="points", marker="hd")
    text = render(fig)
    @test occursin("gappy", text)
    @test occursin("points", text)
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

@testitem "grid layout render supports spans and overlap checks" setup = [TermPlotSetup] begin
    fig = Figure(GridLayout(2, 3; rowweights=[2, 1], colweights=[2, 1, 1], rowgap=1, colgap=2); width=120, height=24, linkx=true)
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
