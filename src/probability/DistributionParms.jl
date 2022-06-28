
export DistributionParmSet, 
FixedDistributionParms, 
LogNormalParms, 
NormalParms, 
PoissonParms, 
sample,
plotPdf,
describe

"""
DistributionParmSet

A type holding parameters for a distribution.
"""
abstract type DistributionParmSet end

"""
draw(d::DistributionParmSet)

Return a random read number from the distribution.
"""
sample(d::DistributionParmSet)::Float64 = error("draw not implemented for $(typeof(d)).")

include("poisson.jl")
include("log_normal.jl")
include("normal.jl")
include("fixed.jl")

"""
usefulMax

Returns a hint for plotting functions.
"""
function usefulMax(d::DistributionParmSet)::Float64 end

"""
plotPdf

Plot the probability density function for this distribution.
"""
function plotPdf(distribution::DistributionParmSet, max::Real=usefulMax(distribution))
  t = collect(0:0.1:max)
  p = pdf.(Ref(distribution), t)
  return Plots.plot(t, p)
end
  
