# General plotting functions

# Convenient prefix(es) for plot files
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
