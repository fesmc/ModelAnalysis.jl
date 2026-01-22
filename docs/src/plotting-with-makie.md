# Plotting with Makie

## Heatmap functions

**heatmapclip, heatmapclip!**

Basic usage with automatic clipping:

```julia
using CairoMakie

begin
    # To see automatic clipping changes, change colorrange:
    colorrange = (-1, 1) # lowclip and highclip
    colorrange = (-4, 1) # no lowclip
    colorrange = (-1, 4) # no highclip
    colorrange = (-4, 4) # no lowclip or highclip
    
    z = randn(20, 20) # data range ±3
    fig = Figure(); ax = Axis(fig[1, 1])
    hm = heatmapclip!(ax, z, colorrange=colorrange)
    Colorbar(fig[1, 2],hm)
    fig
end
```

Additionally use the `scale` argument to scale both `z` and the `colorrange` values,
so that the `Colorbar` is consistent with the data plotted.

```julia
using CairoMakie

begin
    z = rand(20, 20) .* 100
    fig = Figure(); ax = Axis(fig[1, 1])
    hm = heatmapclip!(ax, z, colorrange=(1,10), scale=log10)
    Colorbar(fig[1, 2],hm)
    fig
end

```
