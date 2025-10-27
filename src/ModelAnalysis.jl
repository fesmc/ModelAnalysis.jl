module ModelAnalysis

# Note to build a new myanalysis environment, run the following:
#   mkdir ~/.JuliaEnvironments/myanalysis
# then, in julia:
#   ]
#   activate ~/.JuliaEnvironments/myanalysis
#   add Dates, DataFrames, PrettyTables, CSV, Printf, SkipNan, Statistics, FFTW
#   add JLD2, YAXArrays, NCDatasets, NetCDF
#   add CairoMakie, GeoMakie, Colors, ColorSchemes
#   add NaturalEarth, GLM
#
# Make sure to add the following line to the top of any scripts: 
#   import Pkg; Pkg.activate("$(homedir())/.JuliaEnvironments/myanalysis")
#
import Dates
import DataFrames 
import PrettyTables
import CSV

import Printf; using Printf
import SkipNan; using SkipNan

# Analysis packages
import Statistics; using Statistics
import FFTW

# Data management packages
import JLD2
import YAXArrays; using YAXArrays
import NCDatasets; using NCDatasets
import NetCDF; using NetCDF

# Plotting packages
import CairoMakie; using CairoMakie
import GeoMakie; using GeoMakie
import Colors; using Colors
import ColorSchemes; using ColorSchemes

# Dataset packages
import NaturalEarth; using NaturalEarth
import GLM; using GLM

# Make imported libraries available when ModelAnalysis.jl is used.
export Dates, DataFrames, PrettyTables, CSV
export Prinf, SkipNan
export Statistics, FFTW
export JLD2, YAXArrays, NCDatasets, NetCDF
export CairoMakie, GeoMakie, Colors, ColorSchemes
export NaturalEarth
export GLM

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
export Colorbar_logdiff!

include("Plots_ice.jl")

export gencol_vel;

export make_axis_ice2D;

export preprocess_ice2D_variable;
export heatmap_ice2D_bathymetry!
export contour_ice2D_topo!
export contour_ice2D_icemargin!
export heatmap_ice2D!
export heatmap_ice2D_logdiff!

include("Plots_ocean.jl")

# None yet...

include("Functions.jl")

export calc_bifurcation
export load_V_ice_from_H_ice
export dominant_period

### Additional functions ###

end # module
