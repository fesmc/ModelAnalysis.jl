module ModelAnalysis

# Note to build a new myanalysis environment, run the following:
#   mkdir ~/.JuliaEnvironments/myanalysis
# then, in julia:
#   ]
#   activate ~/.JuliaEnvironments/myanalysis
#   add Statistics, Colors, ColorSchemes, Dates, DataFrames, PrettyTables, CSV, JLD2, Printf, NCDatasets, CairoMakie
# Make sure to add this line to the top of any scripts: 
#   import Pkg; Pkg.activate("$(homedir())/.JuliaEnvironments/myanalysis")
import Dates
import DataFrames 
import PrettyTables
import CSV 

using JLD2
using YAXArrays

using CairoMakie
using GeoMakie

using Colors
using ColorSchemes

using Statistics
using NetCDF
using FFTW

using NaturalEarth
using GLM
using SkipNan

today_prefix = string(Dates.today())*'_';
export today_prefix;

include("Ensembles.jl")
using .Ensembles    # Needed so we can export names from sub-modules at the top-level

#export AbstractModel
#export AbstractModelVariables
#export AbstractEnsemble
#export AbstractEnsembleWeights
export Ensemble
export ensemble_init
export ensemble_save
export ensemble_sort!
export ensemble_linestyling!
export ensemble_get_var!
export ens_stat
export ensemble_members
export collect_variable


include("ClimberEnsembles.jl")
using .ClimberEnsembles

export ClimberModel
export ClimberEnsemble
export ensemble_get_var!

include("Plots.jl")

export plt_prefix;

export ne_110m_coastline
export add_coastlines!
export add_coastlines_0_360!

export make_axis_ice2D;
export gencol_vel;
export heatmap_ice2D_bathymetry!
export contour_ice2D_topo!
export contour_ice2D_ice!
export heatmap_ice2D!
export heatmap_ice2D_logdiff!
export Colorbar_logdiff!

include("Functions.jl")

export calc_bifurcation
export load_V_ice_from_H_ice
export dominant_period

### Additional functions ###

end # module
