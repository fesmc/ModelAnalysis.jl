
# using Meshes
# using Shapefile
# using GeoDataFrames

function point_in_polygon(polygon::Polygon,p::Tuple{Any,Any})
    
    # Assume your shapefile polygon points are in `a.points`
    pts0 = [(p.x, p.y) for p in polygon.points]

    # Remove duplicate endpoint if present
    if pts0[1] == pts0[end]
       pts0 = pts0[1:end-1]
    end

    # Convert polygon points to mesh points
    pts = Meshes.Point.(pts0)

    # Create a polygon from the mesh points
    meshpoly = Meshes.PolyArea(pts)

    # Define your test point
    p_test = Meshes.Point(p[1],p[2])

    # Check if point is inside
    inside = in(p_test, meshpoly)

    return inside
end

function point_in_polygons(shp::DataFrame,p::Tuple{Any,Any})

    inside = false

    for i in 1:nrow(shp)
        if !ismissing(shp[i, "FEATURE"])
            inside = point_in_polygon(shp[i,1],p)
            if inside
                break
            end
        end
    end

    return inside
end
