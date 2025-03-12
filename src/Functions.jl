
#using Statistics

#export calc_bifurcation
#export load_V_ice_from_H_ice

function calc_bifurcation(x,y)
    # x = dT, y = V 
    
    ymid = mean(extrema(y)) 
    kk   = sortperm(abs.(y .- ymid) ./ ymid)
    lim  = mean(x[kk[1:2]])
    
    return(lim)
end

function load_V_ice_from_H_ice(path;varname="H_ice",dx=16e3)
    # Use this function to calculate V_ice from 2D H_ice field, 
    # in case V_ice is not available. 

    # First load variable from reference sim
    ds = NCDatasets.NCDataset(path,"r")

    if !haskey(ds,varname)
        error("load_var:: Error: variable not found in file.")
    end

    # Get dimensions of variable of interest 
    v = ds[varname];
    var  = v[:];
        
    # Close NetCDF file
    close(ds) 

    # Calculate V_ice in [million km^3] at each timestep
    tmp = var.*dx.*dx.*1e-15
    V_ice = mapslices(sum,tmp,dims=[1,2])
    V_ice = vec(V_ice)
    
    return(V_ice)

end