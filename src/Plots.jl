
#using CairoMakie
#using Colors 

#export make_axis_ice2D;
#export gencol_vel;
#export heatmap_ice2D_bathymetry!
#export contour_ice2D_topo!
#export contour_ice2D_ice!
#export heatmap_ice2D!
#export heatmap_ice2D_logdiff!
#export Colorbar_logdiff!

plt_prefix = "plots/"*string(Dates.today())*"_";

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

function make_axis_ice2D(fig_now,xlim,ylim)
    ax = Axis(fig_now,aspect=DataAspect());
    hidedecorations!(ax);
    xlims!(ax,xlim)
    ylims!(ax,ylim)
    return ax
end

function make_axis_ice3D(fig_now,xlim,ylim;
    aspect=(1, 1, 0.1),
    azimuth=-0.2*pi,
    perspectiveness=0.5 )
    ax = Axis3(fig_now,azimuth=azimuth,aspect=aspect,perspectiveness=perspectiveness);
    hidedecorations!(ax);
    xlims!(ax,xlim)
    ylims!(ax,ylim)
    return ax
end

"""
Generate a Colormap of colors suitable for plotting
an ice velocity field. 

Note that `fscale` is defined below as a 
function to modify the scaling of the colormap,
however in practice this is not used by `contourf`. So 
an intermediate workaround is to define the colors at 
the high end of the spectrum twice to give them more weight.
"""
function gencol_vel(levels)


    # Define color palette
    col_vel = ["#0000B9","#0000D7","#0000F4",
                "#003BFF","#003BFF","#009FFF","#009FFF",
                "#25FFD8","#25FFD8","#CBFF33","#CBFF33",
                "#FF6B00","#FF6B00","#7F0000","#7F0000"]
    
    col_vel = ["white","#eff3ff","#9ecae1","#2b83ba","#abdda4","#ffffbf","#fdae61","#d7191c"];

    # Define color-scaling function to shift spectrum down
    fscale(x) = x^0.8;
        
    x = (levels ./ maximum(levels));

    # Generate the initial colormap
    #cmap_var = cgrad(col_vel);
    #cmap_var = cgrad(col_vel,scale=fscale);  # scale argument does not appear to actually be used below in contourf
    cmap_var = cgrad(col_vel,x);
    
    # Whiten the lower level colors
    n = 3
    for k in 1:n
        wt = 1.0 - (k-1)/real(n)
        cmap_var.colors.colors[k] = weighted_color_mean(wt,RGBA(colorant"white"),cmap_var.colors.colors[k]);
    end

    println("n = $n")

    return(cmap_var)
end

"""
Preprocess variable for plotting
"""
function preprocess_ice2D_variable(var; mask = var .> -1e8, zrange = extrema(var[.!isnan.(var)]), scale = identity)
    myvar = copy(var)
    myvar[ mask .== false ] .= NaN
    myvar[var .< zrange[1]] .= NaN
    myvar[var .> zrange[2]] .= NaN
    myvar = scale.(myvar);
    return myvar
end 

"""
Add bathymetry shading to a predefined axis. 
By default, greyshading used, with dark at z=colorrange[1] to white at z=colorrange[2].
z_bed should be modified externally before using this routine (masking, etc) to
facilitate making animations.
"""
function heatmap_ice2D_bathymetry!(ax, xc, yc, z_bed; colorrange = (-500, 0))

    cmap = cgrad([:grey40, :white])
    hm = heatmap!( ax, xc, yc, z_bed, colormap = cmap, colorrange = colorrange, depth_shift = 0 )

    return hm
end

"""
Add surface elevation or ice thickness contours to a predefined axis. 
"""
function contour_ice2D_topo!(ax, xc, yc, myvar; linewidth_zero=1.4)

    ct1 = contour!(ax, xc, yc, myvar, color=:grey30,levels=0:500:5500,linewidth=0.4)
    ct2 = contour!(ax, xc, yc, myvar, color=:grey30,levels=0:1000:5000,linewidth=1.2)
    ct3 = contour!(ax, xc, yc, myvar, color=:grey10,levels=[0],linewidth=linewidth_zero)

    return ct1,ct2,ct3 
end

"""
Add surface elevation or ice thickness contours to a predefined axis. 
"""
function contour3D_ice2D_topo!(ax, xc, yc, myvar; linewidth_zero=1.4)

    ct1 = contour3D!(ax, xc, yc, myvar, color=:grey30,levels=0:500:5500,linewidth=0.4)
    ct2 = contour3D!(ax, xc, yc, myvar, color=:grey30,levels=0:1000:5000,linewidth=1.2)
    ct3 = contour3D!(ax, xc, yc, myvar, color=:grey10,levels=[0],linewidth=linewidth_zero)

    return ct1,ct2,ct3 
end

function contour_ice2D_icemargin!(ax, xc, yc, H_ice; linewidth=1.6)

    ct = contour!(ax, xc, yc, H_ice, color=:black,levels=[0],linewidth=linewidth)

    return ct
end

function heatmap_ice2D!(ax, xc, yc, myvar, cmap)

    # Now plot shading using heatmap to represent the colors accurately
    hm = heatmap!( ax, xc, yc, myvar, colormap = cmap, interpolate = false)
    # These attributes are not used by heatmap it seems, but they should control triangles!
    #hm.extendlow=:auto
    #hm.extendhigh=:auto

    return hm 

end


function heatmap_ice2D_logdiff!(ax, xc, yc, var_diff; colorrange = (-3, 3), rev = false)

    # Define color map
    errormap = cgrad(
        [:blue4, :royalblue, :lightblue, :azure, :white, :white, 
        :white, :white, :thistle1, :pink, :indianred2, :red4] 
    );

    posdiff, negdiff = copy(var_diff), copy(var_diff);
    posdiff[posdiff .<= 0] .= NaN;
    negdiff[negdiff .>= 0] .= NaN;

    lposdiff = log10.(posdiff);
    lnegdiff = log10.( abs.(negdiff) );
    lposdiff[lposdiff .<= 0] .= NaN;
    lnegdiff[lnegdiff .<= 0] .= NaN;

    hmpos = heatmap!(
        ax,
        xc, yc,
        lposdiff,
        colorrange = colorrange,
        colormap = errormap,
        lowclip = errormap[1],
        highclip = errormap[end],
    )

    hmneg = heatmap!(
        ax,
        xc, yc,
        -lnegdiff,
        colorrange = colorrange,
        colormap = errormap,
        lowclip = errormap[1],
        highclip = errormap[end],
    )

    return hmpos
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

#end # module
