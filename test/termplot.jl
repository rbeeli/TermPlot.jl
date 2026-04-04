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

@testitem "datetime formatting" setup = [TermPlotSetup] begin
    fig = Figure(; width=72, height=16)
    panel!(fig; xlabel="Time", ylabel="Value", x_date_format=dateformat"yyyy-mm-dd")
    x = [Date(2024, 1, 1), Date(2024, 1, 3)]
    line!(fig, x, [1.0, 2.0]; label="L")
    ctx = TermPlot._infer_xcontext(fig.panels[1, 1])
    labels = TermPlot._format_x_ticks(
        [Float64(Dates.datetime2epochms(DateTime(Date(2024, 1, 1))))],
        ctx,
        fig.panels[1, 1].xaxis.date_format,
    )
    @test labels == ["2024-01-01"]

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

@testitem "linked layout render" setup = [TermPlotSetup] begin
    fig = Figure(; width=120, height=22, layout=(1, 2), linkx=true, linky=true)
    panel!(fig, 1, 1; title="Left", xlabel="x", ylabel="y")
    panel!(fig, 1, 2; title="Right", xlabel="x", ylabel="y")
    line!(fig.panels[1, 1], 1:5, [1, 2, 3, 2, 1]; label="A")
    line!(fig.panels[1, 2], 2:6, [10, 9, 8, 7, 6]; label="B")
    text = render(fig)
    @test occursin("Left", text)
    @test occursin("Right", text)
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
