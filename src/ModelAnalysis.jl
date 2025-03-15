module ModelAnalysis

# Note to build a new myanalysis environment, run the following:
#   mkdir ~/.JuliaEnvironments/myanalysis
# then, in julia:
#   ]
#   activate ~/.JuliaEnvironments/myanalysis
#   add Statistics, Colors, ColorSchemes, Dates, DataFrames, PrettyTables, CSV, JLD2, Printf, NCDatasets, CairoMakie
# Make sure to add this line to the top of any scripts: 
#   import Pkg; Pkg.activate("$(homedir())/.JuliaEnvironments/myanalysis")
import DataFrames 
import PrettyTables
import CSV 

using CairoMakie
using Colors
using ColorSchemes

using Statistics
using NCDatasets
using FFTW

include("Plots.jl")

export make_axis_ice2D;
export gencol_vel;
export heatmap_ice2D_bathymetry!
export contour_ice2D_topo!
export contour_ice2D_ice!
export heatmap_ice2D!
export heatmap_ice2D_logdiff!
export Colorbar_logdiff!

include("Ensembles.jl")

export ensemble
export ensemble_def
export ensemble_sort!
export ensemble_linestyling!
export ensemble_get_var!
export ens_stat
export ensemble_get_var_ND!
export ensemble_get_var_slice!
export load_time_var
export calc_bifurcation
export load_V_ice_from_H_ice
export ensemble_check 

include("Functions.jl")

export calc_bifurcation
export load_V_ice_from_H_ice
export dominant_period

### Additional functions ###

greetme() = print("Hello World! Revised: 2025-03-15 09:21")

export greetme

end # module ModelAnalysis
