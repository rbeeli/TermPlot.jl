using Pkg

cd(@__DIR__)
Pkg.activate(".")
Pkg.develop(; path=joinpath(@__DIR__, ".."))
Pkg.instantiate()

using Documenter: Documenter
using DocumenterVitepress
using TermPlot

const DOCS_REPO = "github.com/rbeeli/TermPlot.jl"
const DEPLOY_REPO = "github.com/rbeeli/TermPlot.jl.git"

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

function deploy_decision()
    decision = Documenter.deploy_folder(
        Documenter.auto_detect_deploy_system();
        repo=DOCS_REPO,
        devbranch="main",
        devurl="dev",
        push_preview=true,
    )

    if decision.all_ok && !decision.is_preview && decision.subfolder == "dev"
        return Documenter.DeployDecision(;
            all_ok=decision.all_ok,
            branch=decision.branch,
            is_preview=decision.is_preview,
            repo=decision.repo,
            subfolder="",
        )
    end

    return decision
end

deployment = deploy_decision()

Documenter.makedocs(
    sitename="TermPlot.jl",
    modules=[TermPlot],
    format=DocumenterVitepress.MarkdownVitepress(;
        repo=DOCS_REPO,
        devurl="dev",
        devbranch="main",
        description="Pure Julia terminal plotting with Unicode rasterization and ANSI colors.",
        deploy_decision=deployment,
    ),
    pages=pages,
    warnonly=get(ENV, "CI", "false") != "true",
    pagesonly=true,
)

Documenter.deploydocs(
    repo=DEPLOY_REPO,
    target=joinpath("build", "1"),
    versions=nothing,
    push_preview=true,
    devbranch="main",
)
