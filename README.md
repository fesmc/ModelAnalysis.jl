# ModelAnalysis.jl

This package is intended to provide helpful functionality for loading, analyzing and plotting
model (or other) data. It is purposefully broad in scope for now.

Note that the package is under heavy development and things may change. If you will actively
develop anything in the package, please make sure to use your own branch.

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

That's it!

## Ensembles

Example usage of Ensembles.jl with Yelmo model output (1D and 2D):

```julia
    ens = ensemble_def(paths)

    # Add some variables to ensemble
    ensemble_get_var!(ens,"time","yelmo1D.nc",scale=1e-3,newname="ts_time")
    ensemble_get_var!(ens,"uxy_s","yelmo1D.nc",newname="ts_uxy_s")
    ensemble_get_var!(ens,"H_ice","yelmo1D.nc",newname="ts_H_ice")

    ensemble_get_var!(ens,"time","yelmo2D.nc")
    ensemble_get_var!(ens,"xc","yelmo2D.nc")
    ensemble_get_var!(ens,"yc","yelmo2D.nc")
    ensemble_get_var!(ens,"H_ice","yelmo2D.nc")

    # Save to output file
    fileout = "ensemble01.jld2";
    @save fileout ens
    println("Saved $fileout")
```
