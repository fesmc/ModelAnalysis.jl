# General plotting functions

# Convenient prefix(es) for plot files
plt_prefix = "plots/"*string(Dates.today())*"_";

function mysave(fout,fig;px_per_unit=2)
    println("Saving ",fout)
    save(fout,fig,px_per_unit=px_per_unit)
    return fout
end

gapstyles  = [:normal, :dense, :loose, 10]
linestyles0 = [:dot, :dash, :dashdot, :dashdotdot]
linestyles = vec([(ls, gs) for ls in linestyles0, gs in gapstyles])
linestyles = vcat([(:solid,:normal)],linestyles)

# naturalearth("admin_0_countries", 110) # this resolves to `ne_110m_admin_0_countries.geojson`
# https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_coastline.zip
# ne_10m_coastline = naturalearth("ne_10m_coastline")  # this gets the 10m-scale, but explicitly
ne_110m_coastline = naturalearth("ne_110m_coastline")  # this gets the 10m-scale, but explicitly

function add_coastlines!(ax, color=:gray, linewidth=0.5)
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

function heatmapclip!(ax, x, y, z; colorrange=nothing, colormap=nothing, kwargs...)
    
    if isnothing(colormap)
        colormap = ColorSchemes.roma
    end

    loval, hival = minimum(z[.!isnan.(z)]), maximum(z[.!isnan.(z)])

    if isnothing(colorrange)
        colorrange = (loval, hival)
    end
    
    if loval < colorrange[1]
        lowclip = colormap[1]
    else
        lowclip = Makie.automatic
    end
    
    if hival > colorrange[2]
        highclip = colormap[end]
    else
        highclip = Makie.automatic
    end
    
    hm = heatmap!(ax, x, y, z; 
                  colorrange=colorrange, 
                  colormap=colormap, 
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
col_icevel = ColorSchemes.twilight
col_bath = ColorSchemes.bone_1
col_topo =  ColorSchemes.delta # bukavu, fes, oleron, delta, diff, broc, terrain
col_precip = reverse(ColorSchemes.navia)
col_temp = ColorSchemes.coolwarm
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

    # Define color palette
    
    # # white => slate blue => yellow => dark red
    # col_vel = ["white","#eff3ff","#9ecae1","#2b83ba","#abdda4","#ffffbf","#fdae61","#d7191c","#7F0000"];
    # cs = ColorScheme(parse.(Colorant, col_vel))
    # fscale(x) = x.^2.5;
    # x = range(0.0, 1.0, length=N) |> fscale

    # white => red => darkpurple
    # cs = ColorSchemes.RdPu
    # fscale(x) = x.^2.0;
    # x = range(0.0, 1.0, length=N) |> fscale

    # # white => green => darkblue
    # cs = reverse(ColorSchemes.batlowW)
    # fscale(x) = x.^2.0;
    # x = range(0.0, 1.0, length=N) |> fscale

    # multi-color: preferred!
    cs = col_icevel
    fscale(x) = x.^2.3;
    x = range(0.0, 0.98, length=N) |> fscale
    
    cm = get(cs, x)  |> ColorSchemes.ColorScheme #|> reverse
    cmap_colors = cgrad(cm)

    # Define levels too
    minval = max(colorrange[1],0.5) # Only allow minimum value at almost zero
    maxval = colorrange[2]
    cmap_levels = 10 .^ (range(log10(minval),log10(maxval),N))
    cmap_range  = extrema(cmap_levels)

    #xticks    = [0.5,1.0,2.0,5.0,10.0,20.0,50.0,100.0,200.0,500.0,1000.0,2000.0];
    xticks    = [0.5,10.0,100.0,1000.0,2000.0];
    #xticksstr = latexstring.(xticks);
    xticksstr = string.(Int.(round.(xticks)));
    xticksstr[1] = "0"
    xticks    = log10.(xticks);

    return Dict(:levels=>cmap_levels, 
                :colors=>cmap_colors,
                :range=>cmap_range,
                :xticks=>xticks,
                :xticksstr=>xticksstr)
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
                :xticksstr=>xticksstr)
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
                :xticksstr=>xticksstr)
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
