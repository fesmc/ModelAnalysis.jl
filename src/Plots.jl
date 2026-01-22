# General plotting functions

# Convenient prefix(es) for plot files
function plt_prefix(;path="plots")
    return joinpath(path,string(Dates.today())*"_")
end

function mysave(fout,fig;px_per_unit=2)
    println("Saving ",fout)
    save(fout,fig,px_per_unit=px_per_unit)
    return fout
end

gapstyles  = [:normal, :dense, :loose, 10]
linestyles0 = [:dot, :dash, :dashdot, :dashdotdot]
linestyles = vec([(ls, gs) for ls in linestyles0, gs in gapstyles])
linestyles = vcat([(:solid,:normal)],linestyles)

const SUP = Dict(
    '-' => '⁻',
    '0' => '⁰',
    '1' => '¹',
    '2' => '²',
    '3' => '³',
    '4' => '⁴',
    '5' => '⁵',
    '6' => '⁶',
    '7' => '⁷',
    '8' => '⁸',
    '9' => '⁹'
)

to_superscript(n::Integer) = join(SUP[c] for c in string(n))

trim_float(x) = replace(string(x), r"\.0$" => "")

function sci_unicode(x::Real;drop_coeff_one=true,drop_exp_zero=true)
    if x == 0
        return "0"
    end

    exp = floor(Int, log10(abs(x)))
    coeff = x / 10.0^exp
    coeff = round(coeff,digits=2)

    if coeff == 1 && drop_coeff_one
        coeff_str = "10"
    else
        coeff_str = trim_float(coeff)*"·10"
    end

    # When exponent = 0 → simple number
    if exp == 0 && drop_exp_zero
        exp_str = ""
    else
        exp_str = to_superscript(exp)
    end

    return coeff_str*exp_str
end

# naturalearth("admin_0_countries", 110) # this resolves to `ne_110m_admin_0_countries.geojson`
# https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_coastline.zip
# ne_10m_coastline = naturalearth("ne_10m_coastline")  # this gets the 10m-scale, but explicitly
ne_110m_coastline = naturalearth("ne_110m_coastline")  # this gets the 10m-scale, but explicitly

function add_coastlines!(ax; color=:gray, linewidth=0.5)
    # Plot the coastline
    for feature in ne_110m_coastline.features
        coords = feature.geometry.coordinates
        lon = [coord[1] for coord in coords]
        lat = [coord[2] for coord in coords]
        lines!(ax, lon, lat, color=color, linewidth=linewidth)
    end
end

function add_coastlines_0_360!(ax, color=:gray, linewidth=0.5)
    # Plot the coastline
    # for feature in ne_10m_coastline.features
    for feature in ne_110m_coastline.features
        # if feature.geometry.type == "LineString"
        # coords = feature.geometry.coordinates
        coords = feature.geometry.coordinates
        lon = [coord[1] for coord in coords]
        lat = [coord[2] for coord in coords]
        bad = lon .< 0
        lon[bad] .= NaN
        lat[bad] .= NaN

        lines!(ax, lon, lat, color=color, linewidth=linewidth)

        lon = [coord[1] for coord in coords]
        bad = lon .> 0
        lon = [ll < 0 ? ll + 360 : ll for ll in lon]
        lat = [coord[2] for coord in coords]
        lon[bad] .= NaN
        lat[bad] .= NaN
        lines!(ax, lon, lat, color=color, linewidth=linewidth)

        # end
    end
end

"""
    Colorbar_logdiff!(fig_now,hmpos)

TBW
"""
function Colorbar_logdiff!(fig_now,hm; vertical = true, size = Relative(1/2), flipaxis = nothing, label = "")

    if vertical
        width  = Auto();
        height = size;
        if flipaxis === nothing
            flipaxis = true;    # Put labels on right-hand-side
        end
    else
        width  = size;
        height = Auto();
        if flipaxis === nothing
            flipaxis = false;   # Put labels on the bottom
        end
    end 

    Colorbar(
        fig_now,
        hm,
        vertical = vertical,
        flipaxis = flipaxis,
        width = width,
        height = height,
        ticks = (-4:4, [L"$-10^{4}$", L"$-10^{3}$", L"$-10^{2}$", L"$-10^{1}$", L"0", L"$10^{1}$", L"$10^{2}$", L"$10^{3}$", L"$10^{4}$"]), 
        label = label,
    )
end

function Colorbar_with_title(fig,r,c,hm,label;height=Relative(0.5),ticks=nothing)
    
    if isnothing(ticks) 
        ticks = Makie.automatic
    end
    cb_grid = fig[r,c] = GridLayout(2,1)
    cb = Colorbar(cb_grid[2,1], hm; valign=:top,ticks=ticks)
    Label(cb_grid[1,1],"    "*label;valign=:bottom,tellwidth=false)
    rowsize!(cb_grid, 2, height)  # colorbar
    
    return cb
end

@recipe(HmClip) do scene
    Attributes(
        tol = 1e-6,
        colormap = ColorSchemes.roma,
        scale = identity
    )
end

import CairoMakie: plot!
function plot!(p::HmClip)
    tol = p.tol[]

    # This is the *converted* z data (already sampled / expanded)
    z = p.converted[3][]

    zfinite = z[.!isnan.(z)]
    loval, hival = extrema(zfinite)

    cr = get(p, :colorrange, (loval, hival))

    lowclip =
        loval < cr[1] - tol ? p.colormap[][1] : Makie.automatic

    highclip =
        hival > cr[2] + tol ? p.colormap[][end] : Makie.automatic

    p.attributes[:lowclip] = lowclip
    p.attributes[:highclip] = highclip
    p.attributes[:colorrange] = cr

    scale = p.scale[]
    if scale != identity
        z = scale.(z)
        p.attributes[:colorrange] = scale.(p.attributes[:colorrange])
    end
    
    # Delegate to the real Heatmap
    Makie.plot!(p, Heatmap)
end

# function heatmapclip(x, y, z; scale=identity, colorrange=nothing, colormap=nothing, kwargs...)

#     fig = Figure()
#     ax = Axis(fig[1,1])
#     hm = heatmapclip!(ax, x, y, z; scale=scale, colorrange=colorrange, colormap=colormap, kwargs...)

#     return fig, ax, hm
# end

# function heatmapclip!(ax, x, y, z; scale=identity, colorrange=nothing, colormap=nothing, tol=1e-6, kwargs...)
    
#     if isnothing(colormap)
#         colormap = ColorSchemes.roma
#     end

#     loval, hival = minimum(z[.!isnan.(z)]), maximum(z[.!isnan.(z)])

#     if isnothing(colorrange)
#         colorrange = (loval, hival)
#     end
    
#     if loval < colorrange[1]-tol
#         lowclip = colormap[1]
#     else
#         lowclip = Makie.automatic
#     end
    
#     if hival > colorrange[2]+tol
#         highclip = colormap[end]
#     else
#         highclip = Makie.automatic
#     end
    
#     if scale != identity
#         z = scale.(z)
#         colorrange = scale.(colorrange)
#     end

#     hm = heatmap!(ax, x, y, z; 
#                   colorrange=colorrange, 
#                   colormap=colormap, 
#                   lowclip=lowclip, 
#                   highclip=highclip,
#                   kwargs...)

#     return hm
# end

function heatmapclip(args...; scale=identity, colorrange=nothing, colormap=nothing, kwargs...)

    fig = Figure()
    ax = Axis(fig[1,1])
    hm = heatmapclip!(ax, args...; scale=scale, colorrange=colorrange, colormap=colormap, kwargs...)

    return fig, ax, hm
end

"""
    heatmapclip!(args...; scale=identity, colorrange=nothing, colormap=nothing, tol=1e-6, kwargs...)

Create a heatmap with automatic clipping indicators on the colorbar.

This function extends `Makie.heatmap!` by automatically setting `lowclip` and `highclip` 
colors when data values fall outside the specified `colorrange`. Clipped values are 
indicated by colored triangles at the ends of the colorbar using the first and last 
colors of the colormap.

# Arguments
- `args...`: Positional arguments matching any `heatmap!` signature:
    - `heatmapclip!(ax, z)`: Plot matrix `z` on axis `ax`
    - `heatmapclip!(ax, x, y, z)`: Plot matrix `z` with coordinates `x`, `y` on axis `ax`

# Keywords
- `scale=identity`: Function to transform data values (e.g., `log10`, `sqrt`). Applied to 
  both `z` and `colorrange`.
- `colorrange=nothing`: Tuple `(low, high)` defining the color scale limits. If `nothing`, 
  defaults to `(minimum(z), maximum(z))` (excluding NaN values).
- `colormap=nothing`: Colormap to use. If `nothing`, defaults to `ColorSchemes.roma`.
- `tol=1e-6`: Tolerance for determining if data extends beyond `colorrange`. Values below 
  `colorrange[1] - tol` trigger `lowclip`; values above `colorrange[2] + tol` trigger `highclip`.
- `kwargs...`: Additional keyword arguments passed to `heatmap!`.

# Returns
- Returns the heatmap plot object `hm`

# Examples
```julia
using CairoMakie, ColorSchemes

# Basic usage with automatic clipping
z = randn(20, 20) # data range ±3
fig = Figure(); ax = Axis(fig[1, 1])
hm = heatmapclip!(ax, z, colorrange=(-1, 1))
Colorbar(fig[1, 2],hm)
fig

# To see automatic clipping changes,
# change colorrange:
colorrange=(-4, 1) # no lowclip
colorrange=(-1, 4) # no highclip
colorrange=(-4, 4) # no lowclip or highclip
```

# Notes
- NaN values in `z` are automatically excluded when computing data range
- Clipping indicators only appear when data actually extends beyond `colorrange` (within `tol`)
- The `scale` transformation is applied after clipping detection. It is applied both to `z` and `colorrange`
"""
function heatmapclip!(args...; scale=identity, colorrange=nothing, colormap=nothing, tol=1e-6, kwargs...)
    
    # Get a set of colors to work with
    if isnothing(colormap)
        cmap = ColorSchemes.roma
    else
        # Handle both Symbol and ColorScheme types
        cmap = colormap isa Symbol ? colorschemes[colormap] : colormap
    end

    # Extract the data array (z) based on the signature
    # Possible signatures:
    # - heatmap!(ax, z)
    # - heatmap!(ax, x, y, z)
    # - heatmap!(z)
    # - heatmap!(x, y, z)
    
    z = if length(args) == 2 && args[1] isa Makie.AbstractAxis
        # heatmap!(ax, z)
        args[2]
    elseif length(args) == 4 && args[1] isa Makie.AbstractAxis
        # heatmap!(ax, x, y, z)
        args[4]
    else
        error("Unsupported signature for heatmapclip!")
    end

    loval, hival = minimum(z[.!isnan.(z)]), maximum(z[.!isnan.(z)])

    if isnothing(colorrange)
        colorrange = (loval, hival)
    end
    
    if loval < colorrange[1]-tol
        lowclip = cmap[1]
    else
        lowclip = Makie.automatic
    end
    
    if hival > colorrange[2]+tol
        highclip = cmap[end]
    else
        highclip = Makie.automatic
    end
    
    # Apply scale transformation to z and update args
    if scale != identity
        z_scaled = scale.(z)
        colorrange = scale.(colorrange)
        
        # Reconstruct args with scaled z
        args = if length(args) == 2 && args[1] isa Makie.AbstractAxis
            (args[1], z_scaled)
        elseif length(args) == 4 && args[1] isa Makie.AbstractAxis
            (args[1], args[2], args[3], z_scaled)
        elseif length(args) == 1
            (z_scaled,)
        elseif length(args) == 3
            (args[1], args[2], z_scaled)
        else
            args
        end
    end

    hm = heatmap!(args...; 
                  colorrange=colorrange, 
                  colormap=cmap, 
                  lowclip=lowclip, 
                  highclip=highclip,
                  kwargs...)

    return hm
end

function heatmap_temperature!(ax,x,y,z;colorrange=(-30,10),N=15)
    cmap = gencol_temp(N,colorrange=colorrange)
    hm = heatmapclip!( ax, x, y, z, colorrange=colorrange, colormap = cmap[:colors]);
    return hm, cmap
end

function heatmap_precip!(ax,x,y,z;colorrange=(10,1000),N=15)
    cmap = gencol_precip(N,colorrange=colorrange)
    hm = heatmapclip!( ax, x, y, log10.(z), colorrange = log10.(cmap[:range]), colormap = cmap[:colors]);
    return hm, cmap
end


function panel_temperature!(fig,r,c,x,y,z;topo=nothing,colorrange=(-30,10),N=15,
    xlim=nothing,ylim=nothing,title="",label="°C")
    if isnothing(xlim)
        xlim = (minimum(x),maximum(x))
    end
    if isnothing(ylim)
        ylim = (minimum(y),maximum(y))
    end
    ax = make_axis_ice2D(fig[r,c],xlim,ylim);
    ax.title = title;
    hm,_ = heatmap_temperature!(ax,x,y,z,colorrange=colorrange)
    cb = Colorbar_with_title(fig,r,c+1,hm,label)
    if !isnothing(topo)
        (xt, yt, zt) = topo
        contour_ice2D_topo!(ax, xt, yt, zt)
    end
    return hm, cb, ax
end


### Colorschemes ###

### Colorschemes for common variables
col_ghf = ColorSchemes.tol_nightfall
col_lith = ColorSchemes.roma #Cassatt1
col_bath = ColorSchemes.bone_1
col_topo =  ColorSchemes.delta # bukavu, fes, oleron, delta, diff, broc, terrain
col_precip = reverse(ColorSchemes.navia)
col_temp = ColorSchemes.coolwarm

# icevel
col_icevel = ColorSchemes.twilight
# begin
#     cs = ColorSchemes.twilight
#     fscale(x) = x.^2.3;
#     x = range(0.0, 0.98, length=20) |> fscale
    
#     cm = get(cs, x)  |> ColorSchemes.ColorScheme #|> reverse
#     col_icevel = cgrad(cm)
# end

cols = Dict(
    :roma => ColorSchemes.roma,
    :romar => reverse(ColorSchemes.roma),
    :ghf => col_ghf,
    :lith => col_lith,
    :icevel => col_icevel,
    :bath => col_bath,
    :topo => col_topo,
    :precip => col_precip,
    :temp => col_temp,
)

function gencol_vel(N::Integer;colorrange=(0.0,2000.0))

    # multi-color: preferred!
    cs = col_icevel
    fscale(x) = x.^2.3;
    x = range(0.0, 0.98, length=N) |> fscale
    
    cm = get(cs, x)  |> ColorSchemes.ColorScheme #|> reverse
    cmap_colors = cgrad(cm)

    xticks    = [0.5,10.0,100.0,1000.0,2000.0];
    xticksstr = string.(Int.(round.(xticks)));
    xticksstr[1] = "0"
    #xticks    = log10.(xticks);
    ticks = (xticks,xticksstr)

    cmap = gencol_log(N;colors=cmap_colors,colorrange=colorrange,ticks=ticks,logmin=0.5)
    
    return cmap

    # # Define levels too
    # minval = max(colorrange[1],0.5) # Only allow minimum value at almost zero
    # maxval = colorrange[2]
    # cmap_levels = 10 .^ (range(log10(minval),log10(maxval),N))
    # cmap_range  = extrema(cmap_levels)

    # return Dict(:levels=>cmap_levels, 
    #             :colors=>cmap_colors,
    #             :range=>cmap_range,
    #             :xticks=>xticks,
    #             :xticksstr=>xticksstr,
    #             :ticks => (xticks, xticksstr))
end

function gencol_bath(N::Integer;colorrange=(-5000.0,0.0))

    # Define color palette
    cs = col_bath
    fscale(x) = x.^1.0;
    x = range(0.7, 0.9, length=N) |> fscale
    
    cm = get(cs, x)  |> ColorSchemes.ColorScheme #|> reverse
    cmap_colors = cgrad(cm)
    
    # Define levels too
    cmap_levels = range(colorrange[1],colorrange[2],N)
    cmap_range  = extrema(cmap_levels)

    xticks    = [-2000.0,-1000.0,-500.0,-200.0,-100.0,-50.0,0.0];
    #xticksstr = latexstring.(xticks);
    xticksstr = string.(Int.(round.(xticks)));

    return Dict(:levels=>cmap_levels, 
                :colors=>cmap_colors,
                :range=>cmap_range,
                :xticks=>xticks,
                :xticksstr=>xticksstr,
                :ticks => (xticks, xticksstr))
end

function gencol_topo(N::Integer;colorrange=(-5000.0,5000.0))

    # Define color palette
    cs = col_topo
    fscale(x) = x.^1.0;
    x = range(0.0, 1.0, length=N) |> fscale
    
    cm = get(cs, x)  |> ColorSchemes.ColorScheme #|> reverse
    cmap_colors = cgrad(cm)
    
    # Define levels too
    cmap_levels = range(colorrange[1],colorrange[2],N)
    cmap_range  = extrema(cmap_levels)

    xticks    = [-2000.0,-1000.0,-500.0,-200.0,-100.0,-50.0,0.0,50.0,100.0,200.0,500.0,1000.0,2000.0];
    #xticksstr = latexstring.(xticks);
    xticksstr = string.(Int.(round.(xticks)));

    return Dict(:levels=>cmap_levels, 
                :colors=>cmap_colors,
                :range=>cmap_range,
                :xticks=>xticks,
                :xticksstr=>xticksstr,
                :ticks => (xticks, xticksstr))
end

function logticks(minval, maxval; sub=[1,2,3,4,5,6,7,8,9], labelmajors=true, use_latex=false)

    dmin = floor(Int, log10(minval))
    dmax = ceil(Int, log10(maxval))

    ticks = Float64[]
    labels = Any[]

    for k in dmin:dmax
        decade = 10.0^k
        # major tick
        push!(ticks, decade)
        if labelmajors
            if use_latex
                push!(labels, L"10^{%$k}")
            else
                push!(labels, sci_unicode(decade,drop_coeff_one=true,drop_exp_zero=false))
            end
        else
            push!(labels, "")
        end

        # sub-ticks
        for s in sub
            t = s * decade
            if minval <= t <= maxval
                push!(ticks, t)
                push!(labels, "")  # unlabeled minor tick
            end
        end
    end

    return log10.(ticks), labels
end


function gencol_log(N::Integer; colorrange = (0, 1000), colors = ColorSchemes.roma, logmin=1e-5, 
                ticks = nothing)

    # enforce nonzero min (similar to your logic)
    maxval = colorrange[2]
    rawmin = colorrange[1]
    minval = rawmin <= 0 ? logmin : rawmin

    # log-spaced contour levels
    cmap_levels = logrange(minval, maxval, N)
    cmap_range  = extrema(cmap_levels)

    if isnothing(ticks)
        (xticks, xticksstr) = logticks(minval,maxval)
    else
        if typeof(ticks) == typeof(ticks)==Tuple{Vector{Float64}, Vector{String}}
            (xticks, xticksstr) = ticks
            xticks = log10.(xticks)
        else
            #xticksstr = sci_unicode.(ticks)
            xticksstr = string.(ticks)
            xticks = log10.(ticks)
            
        end
    end

    cmap_colors = colors

    return Dict(
        :levels => cmap_levels,
        :colors => cmap_colors,
        :range  => cmap_range,
        :xticks => xticks,
        :xticksstr => xticksstr,
        :ticks => (xticks, xticksstr)
    )
end

function gencol_precip(N::Integer;colorrange=(10,1200))

    # Define levels too (log10 scaled range)
    minval = max(colorrange[1],0.5) # Only allow minimum value at almost zero
    maxval = colorrange[2]
    cmap_levels = logrange(minval,maxval,N)
    cmap_range  = extrema(cmap_levels)

    xticks    = [0.5,10.0,30.0,100.0,300.0,1000.0];
    #xticksstr = latexstring.(xticks);
    xticksstr = string.(Int.(round.(xticks)));
    xticksstr[1] = "0"
    xticks    = log10.(xticks);

    # Define color palette
    cs_orig = col_precip
    
    cs = ColorScheme([cs_orig[x] for x in range(0, 0.85, length=256)])
    cmap_colors = cgrad(cs,N,scale=x->x^0.5,categorical=true)

    return Dict(
            :levels=>cmap_levels, 
            :colors=>cmap_colors,
            :range=>cmap_range,
            :xticks=>xticks,
            :xticksstr=>xticksstr,
            :ticks=>(xticks,xticksstr)
            )
end

function gencol_temp(N::Integer;colorrange=(-30,10),colormap=col_temp)

    lo, hi = colorrange

    # Compute fraction where zero lies in [0,1] for the gradient
    zero_position = (0 - lo) / (hi - lo)
    zero_position = clamp(zero_position, 0.0, 1.0)  # safety

    # Sample the colorscheme symmetrically around the midpoint
    positions = range(0, 1, length=256)
    # Remap positions so that 0.75 in your data maps to 0.5 in the colorscheme
    remapped = @. (positions - zero_position) / (2 * max(zero_position, 1 - zero_position)) + 0.5
    remapped = clamp.(remapped, 0, 1)
    #mycolors = ColorSchemes.coolwarm[remapped]

    colorscheme_positions = ifelse.(positions .<= zero_position,
    positions ./ zero_position .* 0.5,  # stretch first part
    0.5 .+ (positions .- zero_position) ./ (1 - zero_position) .* 0.5)  # stretch second part

    # Sample new colors
    mycolors = colormap[colorscheme_positions]

    # Define levels
    cmap_levels = range(lo, hi, N)
    cmap_range  = (lo, hi)

    xticks    = [-30,-20,-10,0,10];
    xticksstr = string.(Int.(round.(xticks)));

    # Define color palette
    #cs_orig = ColorSchemes.coolwarm
    #cs = ColorScheme([cs_orig[x] for x in range(0.0, 1.0, length=256)])
    cs = ColorScheme(mycolors)
    cmap_colors = cgrad(cs,N,categorical=true)
    
    return Dict(:levels=>cmap_levels, 
                :colors=>cmap_colors,
                :range=>cmap_range,
                :xticks=>xticks,
                :xticksstr=>xticksstr)
end

#end # module
