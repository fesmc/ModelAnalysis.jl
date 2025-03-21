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

To do