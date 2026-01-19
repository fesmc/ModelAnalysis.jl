# Plotting functions specific to ice sheets

function make_axis_ice2D(fig_now,xlim=nothing,ylim=nothing;title=nothing)
    ax = Axis(fig_now,aspect=DataAspect())
    hidedecorations!(ax)
    xlims!(ax,xlim)
    ylims!(ax,ylim)
    # if !isnothing(xlim)
    #     xlims!(ax,xlim)
    # end
    # if !isnothing(ylim)
    #     ylims!(ax,ylim)
    # end
    if !isnothing(title)
        ax.title = title
    end
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

function IcePanel(fig,r,c,xc,yc,var,cmap,z_srf,H_ice;xlim=nothing,ylim=nothing,title=nothing,units="",scale=identity)
    if isnothing(xlim) 
        xlim = extrema(xc)
    end
    if isnothing(ylim) 
        ylim = extrema(yc)
    end

    ax = make_axis_ice2D(fig[r,c[1]],xlim,ylim;title=title);
    
    # Add shading showing variable
    hm = heatmapclip!( ax, xc, yc, var, scale = scale, colormap = cmap[:colors], colorrange = cmap[:range]);
    cb = Colorbar_with_title(fig,r,c[2],hm,units,ticks=cmap[:ticks])

    # Add standard elevation contours on top too
    ct_srf = contour_ice2D_topo!(ax, xc, yc, z_srf);
    ct_ice = contour_ice2D_icemargin!(ax, xc, yc, H_ice);

    return ax, hm, cb
end

function plot_icesheet(x,y,uxy,H_ice,z_srf,z_bed; time=nothing,units="kyr",
    xlim=extrema(x),ylim=extrema(y))

    # Get specific field to plot with title
    if !isnothing(time)
        time_str = @sprintf("%5.1f",time)
        time_label = string(time_str," $units")
    end

    uxy_plt   = preprocess_ice2D_variable(uxy; mask = H_ice .> 0, zrange=(0.5,10e3), scale = log10);
    
    # Define cmap using our predefined function for velocity colors
    cmap_v = gencol_vel(20;colorrange=(0.0,2000.0))
    
    ### Define the figure
    fig = Figure(; size = (450,500), font = "CMU Serif", fontsize= 18);
    
    r = 1:5
    c = 1
    fg = fig[1,1] = GridLayout(1,2)

    ax1 = make_axis_ice2D(fg[1,1],xlim,ylim);
    
    cmap_t = gencol_topo(50;colorrange=[-11.2e3,12e3])
    hm_topo = heatmap!(ax1, x, y, z_bed,colormap = cmap_t[:colors], colorrange = cmap_t[:range]);
    ct_topo = contour_ice2D_bath!(ax1, x, y, z_bed);
    
    # Add shading showing velocity
    hm1 = heatmapclip!( ax1, x, y, uxy_plt, colormap = cmap_v[:colors], colorrange = log10.(cmap_v[:range]));
    
    cb1 = Colorbar_with_title(fg,1,2,hm1,"m/yr",ticks = (cmap_v[:xticks], cmap_v[:xticksstr]))
    #cb1 = Colorbar_with_title(fig,1:3,2,hm1,"m/yr",ticks = (cmap_v[:xticks], cmap_v[:xticksstr]),height=Relative(0.9))
    #cb2 = Colorbar_with_title(fig,4:5,2,hm_topo,"m", height=Relative(0.6))
    
    # Add standard elevation contours on top too
    ct_srf = contour_ice2D_topo!(ax1, x, y, z_srf);
    ct_ice = contour_ice2D_icemargin!(ax1, x, y, H_ice);

    # Add time label
    if !isnothing(time)
        txt1 = text!(
            ax1, 0, 1, font = :bold,
            align = (:left, :top), offset = (4, -2),
            space = :relative, fontsize = 16,
            text = time_label,
        )
    end

    # Save figure 
    #nt_str = @sprintf("%03i",q)
    #fout = mysave(string("plots/"*file_prefix*"_",nt_str,".png"),fig)

    return fig
end

"""
Add bathymetry shading to a predefined axis. 
By default, greyshading used, with dark at z=colorrange[1] to white at z=colorrange[2].
z_bed should be modified externally before using this routine (masking, etc) to
facilitate making animations.
"""
function heatmap_ice2D_bathymetry!(ax, xc, yc, z_bed; colorrange = (-500, 0))

    cmap = gencol_bath(20;colorrange=colorrange)

    hm = heatmap!( ax, xc, yc, z_bed, colormap = cmap[:colors], colorrange = colorrange, depth_shift = 0 )

    return hm
end

"""
Add bathymetry contours to a predefined axis. 
"""
function contour_ice2D_bath!(ax, xc, yc, myvar)

    ct1 = contour!(ax, xc, yc, myvar, color=:grey70,levels=-1000:500:0,linewidth=0.8)
    
    return ct1
end

"""
Add surface elevation or ice thickness contours to a predefined axis. 
"""
function contour_ice2D_topo!(ax, xc, yc, myvar; color=[:grey30,:grey30,:grey10], linewidth=[0.4,1.2,1.4])

    ct1 = contour!(ax, xc, yc, myvar, color=color[1],levels=0:500:5500,linewidth=linewidth[1])
    ct2 = contour!(ax, xc, yc, myvar, color=color[2],levels=0:1000:5000,linewidth=linewidth[2])
    ct3 = contour!(ax, xc, yc, myvar, color=color[3],levels=[0],linewidth=linewidth[3])

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