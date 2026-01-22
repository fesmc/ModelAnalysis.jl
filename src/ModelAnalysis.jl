module ModelAnalysis

# Note to build a new myanalysis environment, run the following:
#   mkdir ~/.JuliaEnvironments/myanalysis
# then, in julia:
#   ]
#   activate ~/.JuliaEnvironments/myanalysis
#   add Dates, DataFrames, PrettyTables, CSV
#   add Printf, SkipNan, Statistics, GLM, FFTW
#   add Interpolations, DSP, ImageFiltering
#   add JLD2, YAXArrays, NCDatasets, NetCDF
#   add CairoMakie, GeoMakie, Colors, ColorSchemes
#   add NaturalEarth
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
import GLM; using GLM
import FFTW
import Interpolations
import DSP
import ImageFiltering

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

# Make imported libraries available when ModelAnalysis.jl is used.
export Dates, DataFrames, PrettyTables, CSV
export Prinf, SkipNan
export Statistics, GLM, FFTW
export Interpolations, DSP, ImageFiltering
export JLD2, YAXArrays, NCDatasets, NetCDF
export CairoMakie, GeoMakie, Colors, ColorSchemes
export NaturalEarth

today_prefix = string(Dates.today())*'_';
export today_prefix;

#####
##### Include modules and export functions to use at top level
#####

# Ensembles
include("Ensembles.jl")
using .Ensembles    # Needed so we can export names from sub-modules at the top-level

export AbstractModel
export AbstractModelVariables
export AbstractEnsemble
export AbstractEnsembleWeights
export Ensemble
export ensemble_init
export ensemble_save
export ensemble_set
export subset
export sort!
export ensemble_linestyling!
export ensemble_get_var!
export ens_stat
export ensemble_members
export collect_variable

# ClimberEnsembles
include("ClimberEnsembles.jl")
#using .ClimberEnsembles # Needed so we can export names from sub-modules at the top-level
#
#export ClimberModel
#export ClimberEnsemble
#export ensemble_get_var!

#####
##### Additional functions (not in sub-modules)
#####

include("Plots.jl")

export plt_prefix
export linestyles
export mysave
export ne_110m_coastline
export add_coastlines!
export add_coastlines_0_360!
export Colorbar_logdiff!
export Colorbar_with_title
export HmClip
export heatmapclip
export heatmapclip!
export heatmap_temperature!
export heatmap_precip!
export panel_temperature!

export col_bath, col_ghf, col_lith
export col_precip, col_temp
export col_icevel
export cols
export gencol_vel
export gencol_bath
export gencol_topo
export gencol_log
export gencol_pr
export gencol_tas

include("Plots_ice.jl")

export make_axis_ice2D
export preprocess_ice2D_variable
export IcePanel
export plot_icesheet
export heatmap_ice2D_bathymetry!
export contour_ice2D_bath!
export contour_ice2D_topo!
export contour_ice2D_icemargin!
export heatmap_ice2D!
export heatmap_ice2D_logdiff!

include("Plots_ocean.jl")

# None yet...

include("Functions.jl")

export MissingToNaN
export clean
export print_row
export global_extrema
export calc_bifurcation
export load_V_ice_from_H_ice
export dominant_period

end # module
