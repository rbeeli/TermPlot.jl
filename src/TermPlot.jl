module TermPlot

using Dates
using Printf
using TimeZones

export Axis,
       Panel,
       GridSeam,
       GridLayout,
       Figure,
       Line,
       Stem,
       Scatter,
       Bar,
       HLine,
       VLine,
       Annotation,
       panel!,
       line!,
       stem!,
       scatter!,
       bar!,
       stackedbar!,
       hline!,
       vline!,
       annotate!,
       xlims!,
       ylims!,
       yscale!,
       render,
       render!,
       render_svg,
       render_svg!

include("termplot/core.jl")
include("termplot/analysis.jl")
include("termplot/draw.jl")
include("termplot/render.jl")
include("termplot/svg.jl")
include("termplot/api.jl")

end
