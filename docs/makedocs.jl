using Pkg

cd(@__DIR__)
Pkg.activate(".")
Pkg.develop(; path=joinpath(@__DIR__, ".."))
Pkg.instantiate()

using Documenter: Documenter
using DocumenterVitepress
using TermPlot

pages = [
    "Home" => "index.md",
    "Examples" => [
        "Overview" => "examples/index.md",
        "Basic Line Plots" => "examples/basic.md",
        "Dual Axes" => "examples/dual_axes.md",
        "Stacked Bars" => "examples/stacked_bars.md",
        "Linked Layouts" => "examples/linked_layouts.md",
    ],
]

Documenter.makedocs(
    sitename="TermPlot.jl",
    modules=[TermPlot],
    format=DocumenterVitepress.MarkdownVitepress(;
        repo="github.com/rbeeli/TermPlot.jl",
        devurl="dev",
        devbranch="main",
        deploy_url="https://rbeeli.github.io/TermPlot.jl",
        description="Pure Julia terminal plotting with Unicode rasterization and ANSI colors.",
    ),
    pages=pages,
    warnonly=get(ENV, "CI", "false") != "true",
    pagesonly=true,
)

DocumenterVitepress.deploydocs(
    repo="github.com/rbeeli/TermPlot.jl.git",
    push_preview=true,
    devbranch="main",
    devurl="dev",
)
