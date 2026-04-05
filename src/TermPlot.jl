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
       panel!,
       line!,
       stem!,
       scatter!,
       bar!,
       stackedbar!,
       hline!,
       vline!,
       xlims!,
       ylims!,
       yscale!,
       render,
       render!

include("termplot/core.jl")
include("termplot/analysis.jl")
include("termplot/draw.jl")
include("termplot/render.jl")
include("termplot/api.jl")

end
