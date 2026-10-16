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

    fig = with_theme(theme_ice()) do
        fig = Figure(; size = (450,500))
        ax  = make_axis_ice2D(fig[1,1],xlim,ylim)
        p   = icesheet_panel!(ax, x, y, uxy, z_srf, H_ice; z_bed=z_bed)
        icesheet_colorbar(fig[1,2], p.hm)

        if !isnothing(time)
            text!(ax, 0, 1, font = :bold, align = (:left, :top), offset = (4, -2),
                  space = :relative, text = @sprintf("%5.1f %s", time, units))
        end
        fig
    end

    return fig
end

"""
    theme_ice(; fontsize=14)

House style for ice-sheet figures: Makie's default font, plain axes, no grid.
Sub- and superscripts in labels as Unicode characters (Hₘₐₓ, km²). Use with
`with_theme(theme_ice()) do ... end` or `set_theme!(theme_ice())`.
"""
function theme_ice(; fontsize=14)
    return Theme(
        fontsize = fontsize,
        Axis = (titlesize = fontsize, titlefont = :regular,
                xgridvisible = false, ygridvisible = false,
                topspinevisible = false, rightspinevisible = false),
        Colorbar = (ticklabelsize = fontsize - 2, labelsize = fontsize),
        Legend = (framevisible = false, labelsize = fontsize - 2),
    )
end

# Background colors of ice-sheet maps
col_land  = :gray88
col_ocean = :white

"""
    icesheet_panel!(ax, x, y, uxy_s, z_srf, H_ice; kwargs...)

Draw an ice-sheet map into the axis `ax`: land (z_bed >= z_sl) in gray with
bathymetry contours, the surface velocity (log scale, ice only) as shading,
the surface elevation as contours (every 500 m, thick every 1000 m), the ice
margin, optionally a reference extent, and a label with the maximum ice
thickness and the ice volume (`icesheet_stats`). `x`, `y` in km.

# Keywords
- `z_bed=nothing`: bed elevation [m]; without it no background is drawn and
  the volume counts all ice (not only above flotation).
- `z_sl=0.0`: sea level [m] (scalar or field).
- `ref=nothing`: reference ice mask (e.g. an observed or initial extent),
  drawn as a dashed contour in `ref_color`.
- `Hmin=1.0`: [m] ice thickness defining the ice cover.
- `cmap=gencol_vel(20)`: velocity colormap (see `gencol_vel`).
- `stats=true`: add the label; `stats_align` sets its corner, `stats_mask`
  limits it to a region (e.g. without neighbouring ice sheets).
- `area`: [m^2] cell area for the volume, field or scalar (default: the map
  area from the spacing of `x`; see `icesheet_stats`).

Returns a NamedTuple with the velocity heatmap `hm` (for `icesheet_colorbar`),
the colormap `cmap` and the `stats`.
"""
function icesheet_panel!(ax, x, y, uxy_s, z_srf, H_ice;
                         z_bed = nothing, z_sl = 0.0, ref = nothing, ref_color = :orangered,
                         Hmin = 1.0, cmap = gencol_vel(20; colorrange = (0.0, 2000.0)),
                         stats = true, stats_align = (:left, :bottom), stats_mask = nothing,
                         area = (abs(x[2] - x[1]) * 1e3)^2)

    H   = Float64.(coalesce.(H_ice, 0.0))
    ice = H .> Hmin

    # Background: land and bathymetry
    if !isnothing(z_bed)
        zb = Float64.(coalesce.(z_bed, NaN)) .- z_sl
        heatmap!(ax, x, y, ifelse.(zb .>= 0.0, 1.0, NaN), colormap = [col_land, col_land],
                 colorrange = (0, 1))
        contour_ice2D_bath!(ax, x, y, zb)
    end

    # Surface velocity on the ice, floored at the lower end of the colormap
    u  = Float64.(coalesce.(uxy_s, 0.0))
    u  = ifelse.(ice, max.(u, cmap[:range][1]), NaN)
    hm = heatmapclip!(ax, x, y, u; colormap = cmap[:colors], colorrange = cmap[:range],
                      scale = log10)

    # Surface elevation contours and margin
    contour_ice2D_topo!(ax, x, y, ifelse.(ice, Float64.(coalesce.(z_srf, NaN)), NaN))
    contour_ice2D_icemargin!(ax, x, y, H; Hmin = Hmin)

    if !isnothing(ref)
        contour!(ax, x, y, Float64.(ref), levels = [0.5], color = ref_color,
                 linewidth = 1.4, linestyle = :dash)
    end

    s = icesheet_stats(H, area; z_bed = z_bed, z_sl = z_sl, Hmin = Hmin, mask = stats_mask)
    if stats
        x0 = stats_align[1] == :left ? 0.0 : 1.0
        y0 = stats_align[2] == :bottom ? 0.0 : 1.0
        text!(ax, x0, y0, space = :relative, align = stats_align,
              offset = (x0 == 0 ? 4 : -4, y0 == 0 ? 4 : -4),
              fontsize = 0.85 * Makie.theme(:fontsize)[],
              text = @sprintf("Hₘₐₓ = %.1f km\nV = %.1f m SLE", s.H_max / 1e3, s.V_sle))
    end

    return (hm = hm, cmap = cmap, stats = s)
end

"""
    icesheet_colorbar(pos, hm; cmap=gencol_vel(20), label="Surface velocity [m/yr]", kwargs...)

Colorbar for the velocity shading of `icesheet_panel!`, with the ticks of `cmap`.
"""
function icesheet_colorbar(pos, hm; cmap = gencol_vel(20; colorrange = (0.0, 2000.0)),
                           label = "Surface velocity [m/yr]", kwargs...)
    return Colorbar(pos, hm; ticks = cmap[:ticks], label = label, kwargs...)
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

"""
Add the ice margin (H_ice > Hmin) as a contour to a predefined axis.
"""
function contour_ice2D_icemargin!(ax, xc, yc, H_ice; Hmin=1.0, color=:black, linewidth=1.6,
                                  linestyle=:solid)

    mask = Float64.(coalesce.(H_ice, 0.0) .> Hmin)
    ct = contour!(ax, xc, yc, mask, color=color, levels=[0.5], linewidth=linewidth,
                  linestyle=linestyle)

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