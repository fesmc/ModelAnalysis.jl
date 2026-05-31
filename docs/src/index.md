# ModelAnalysis.jl

Tools for analysing model output in Julia. Bundles helpers for loading
ensembles of NetCDF model output, summarising and subsetting them, and plotting
with Makie.

## Installation

For now, install as a local development package:

```julia
using Pkg
Pkg.dev("path/to/ModelAnalysis.jl")
```

## Quick example

```julia
using ModelAnalysis

# Load an ensemble from a directory containing one subdirectory per member
ens = Ensemble("runs/experiment1")

# Load a variable from each member; namespaced by source file
ensemble_get_var!(ens, "timesteps.nc", "speed")
# => ens.v[:timesteps][:speed] is a length-ens.N vector, one entry per member

# Per-member summary statistics
mean_speed = ens_stat(ens, :timesteps, :speed, mean)

# Subset by parameter values
fast = filter(p -> p.dx == 16, ens)
```

See the [Ensembles](ensembles.md) page for the full workflow.
