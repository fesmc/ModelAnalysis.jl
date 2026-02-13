## Preamble #############################################
cd(@__DIR__)
import Pkg; Pkg.activate(".")
using Revise
using ModelAnalysis
#########################################################

# Define some test paths to generate an ensemble
HOME = homedir()
paths = [
    "$HOME/models/yelmox/output/16KM/test",
    "$HOME/models/yelmox/output/16KM/test",
    "$HOME/models/yelmox/output/16KM/test"
]

# Define a new ensemble
ens = Ensemble(paths)

# Load a variable
ensemble_get_var!(ens,"yelmo2D.nc","H_ice")