# Plotting functions specific to ice sheets

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
function gencol_vel_palette(levels::Vector{<:Real})

    # Define color palette
    
    # # white => slate blue => yelmo => dark red
    # col_vel = ["white","#eff3ff","#9ecae1","#2b83ba","#abdda4","#ffffbf","#fdae61","#d7191c","#7F0000"];
    # cs = ColorScheme(parse.(Colorant, col_vel))
    # fscale(x) = x.^2.5;
    # x = range(0.0, 1.0, length=20) |> fscale
    # cm = get(cs, x)  |> ColorSchemes.ColorScheme #|> reverse
    # cmap_var = cgrad(cm)

    # white => red => darkpurple
    # fscale(x) = x.^2.0;
    # x = range(0.0, 1.0, length=20) |> fscale
    # cm = get(ColorSchemes.RdPu, x)  |> ColorSchemes.ColorScheme #|> reverse
    # cmap_var = cgrad(cm)

    # # white => green => darkblue
    # fscale(x) = x.^2.0;
    # x = range(0.0, 1.0, length=20) |> fscale
    # cm = get(reverse(ColorSchemes.batlowW), x)  |> ColorSchemes.ColorScheme
    # cmap_var = cgrad(cm)

    # multi-color: preferred!
    fscale(x) = x.^2.3;
    x = range(0.0, 0.98, length=20) |> fscale
    cm = get(ColorSchemes.twilight, x)  |> ColorSchemes.ColorScheme #|> reverse
    cmap_var = cgrad(cm)

    return(cmap_var)
end

function gencol_vel(maxval::Real,n::Integer)

    minval = 0.5 # Almost zero
    cmap_levels = 10 .^ (range(log10(minval),log10(maxval),n))
    cmap_colors = gencol_vel_palette(log10.(cmap_levels))
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