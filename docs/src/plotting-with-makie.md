# Plotting with Makie

## Variable manipulation

Sometimes variables we load from files do not have the right type to be plotted by `Makie`, 
or need to be processed in some way.

The function `clean` can be used to help cleanup variables by performing some or all of the following operations:

- missing values are replaced with NaNs
- values outside of mask are set to NaN
- values outside of desired range are set to limits, specific value(s) or NaN (default)
- scale values by a function

```julia
using Random
using CairoMakie

# Reproducible random data
Random.seed!(42)

# Create random data with missing values
var = Matrix{Union{Missing, Float64}}(randn(5, 5))
var[2, 3] = missing
var[4, 1] = missing

# Plot a heatmap, with missing data (this is ok)
heatmap(var)

# Define a mask (keep only upper-left 3×3 block)
mask = falses(5, 5)
mask[1:3, 1:3] .= true

# Clean the data:
# - convert missing → NaN
# - apply mask
# - restrict values to [-1, 1]
# - clip outliers to the range
# - scale values by a factor of 2
clean_var = clean(
    var;
    mask = mask,
    zrange = (-1.0, 1.0),
    scale = x -> 2x,
)

# Plot heatmap of clean var
heatmap(clean_var)

```

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

## Ice-sheet maps

`icesheet_panel!` draws the standard ice-sheet map into an existing axis:
surface velocity (log scale, `gencol_vel`) as shading, surface elevation
contours (every 500 m, thick every 1000 m), the ice margin, land and
bathymetry from `z_bed`, optionally a reference extent (dashed), and a label
with the maximum ice thickness and the ice volume in m SLE
(`icesheet_stats`, ice above flotation). Use `theme_ice()` for the house style.

```julia
using ModelAnalysis, NCDatasets

ds = NCDataset("yelmo.nc")
x, y = ds["xc"][:], ds["yc"][:]
k = length(ds["time"])
get(v) = ds[v][:, :, k]

with_theme(theme_ice()) do
    fig = Figure(size = (450, 500))
    ax = Axis(fig[1, 1], aspect = DataAspect()); hidedecorations!(ax); hidespines!(ax)
    p = icesheet_panel!(ax, x, y, get("uxy_s"), get("z_srf"), get("H_ice");
                        z_bed = get("z_bed"), z_sl = get("z_sl"),
                        area = ds["area"][:, :] .* 1e6)   # true cell area [m^2]
    icesheet_colorbar(fig[1, 2], p.hm)
    fig
end
```

On a projected grid pass the true cell `area` (Yelmo writes it in km^2):
the default, the map area dx^2, overestimates the volume away from the
true-scale latitude (about 8% at 60°N for a stereographic grid true at 70°N).
