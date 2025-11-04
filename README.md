# ModelAnalysis.jl

This package is intended to provide helpful functionality for loading, analyzing and plotting
model (or other) data. It is purposefully broad in scope for now.

Note that the package is under heavy development and things may change. If you will actively
develop anything in the package, please make sure to use your own branch.

## Contributing to ModelAnalysis

The idea behind this package is to group together convenient functionality into one package so
that we each can benefit from each other's innovations. Sometimes this will come in some big function 
to make e.g. a particular kind of figure. But more often, it should come in small snippets, or building blocks,
that are useful in different contexts. These could be a set of color palettes that are useful for plotting
ice velocity (see `src/Plots_ice.jl:gencol_vel`), ocean bathymetry etc. 
Or functions to add coastlines to a given Axis using the NaturalEarth dataset (see `src/Plots.jl:add_coastlines`).

## Installing / using ModelAnalysis

For now, ModelAnalysis.jl should be used like any local package under development. This means

1. Clone the repository to a local directory.

2. Add ModelAnalysis.jl to your workspace in Julia using `Pkg.dev()` rather than `Pkg.add()`:

    ```julia
    using Pkg; Pkg.dev("path/to/ModelAnalysis.jl")
    ```

3. Now use it like a normal package. If you will make changes to it, then consider also
loading Revise.jl (and do so before using ModelAnalysis.jl):

    ```julia
    using Revise
    using ModelAnalysis
    ```

That's it! Now ModelAnalysis functions are available in your script and you
can make changes within the package locally and they will be visible in the script too.

## Plotting

To do

## Ensembles

Example usage of Ensembles.jl with Yelmo model output (1D and 2D):

```julia
    ens = Ensemble(paths)

    # Add some variables to ensemble
    ensemble_get_var!(ens,"yelmo1D.nc","time",newname="ts_time",scale=1e-3)
    ensemble_get_var!(ens,"yelmo1D.nc","uxy_s",newname="ts_uxy_s")
    ensemble_get_var!(ens,"yelmo1D.nc","H_ice",newname="ts_H_ice")

    ensemble_get_var!(ens,"yelmo2D.nc","time")
    ensemble_get_var!(ens,"yelmo2D.nc","xc")
    ensemble_get_var!(ens,"yelmo2D.nc","yc")
    ensemble_get_var!(ens,"yelmo2D.nc","H_ice")

    # Save to output file (optionally setting a new name for the ensemble object `ens01` for when it is loaded into memory again)
    ensemble_save("ensemble01.jld2",ens,"ens01")
```
