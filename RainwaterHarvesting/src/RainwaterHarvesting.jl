module RainwaterHarvesting

using DataFrames, Dates, CSV, Plots

export ModelParameters, Tank, AnnualRainfallData, RainfallData
export run_timestep!, run_timesteps, get_inflow, get_consumption
export plot

include("types.jl")
include("simulation.jl")
include("viz.jl")


end # module RainwaterHarvesting
