
function MissingToNaN(dat)
    dat = float.(dat)
    dat = coalesce.(dat,NaN)
    return dat
end

"""
Clean a variable, so that:
- missing values are replaced with NaNs 
- values outside of mask are set to NaN 
- values outside of desired range are set to limits or NaN
"""
function clean(var; mask = nothing, zrange = nothing, scale = identity, outlier_value = NaN)
    
    # Copy to a new variable
    myvar = copy(var)

    # Convert all missing to NaN for consistency
    myvar = MissingToNaN(var)

    # mask:
    if !isnothing(mask)
        myvar[ mask .== false ] .= NaN
    end

    # zrange:
    if isnothing(zrange)
        zrange = extrema(var[.!isnan.(var)])
    end

    # Limit the variable range to desired range (zrange or outlier_value)
    if isnothing(outlier_value)
        myvar[var .< zrange[1]] .= zrange[1]
        myvar[var .> zrange[2]] .= zrange[2]
    else
        if length(outlier_value)==1
            myvar[var .< zrange[1]] .= outlier_value
            myvar[var .> zrange[2]] .= outlier_value
        else
            myvar[var .< zrange[1]] .= outlier_value[1]
            myvar[var .> zrange[2]] .= outlier_value[2]
        end
    end
    
    # Scale variable as needed:
    myvar = scale.(myvar);

    return myvar
end 

### DataFrames

"""
Print a row of data transposed
"""
function print_row(row)
    for (name, val) in zip(names(row), row)
        println(rpad(name, 20), val)
    end
end

##################

"""
Get extrema over multiple arrays
"""
# function global_extrema(arrays)
#     mn, mx = extrema(collect(first(arrays)))
#     for A in Iterators.drop(arrays, 1)
#         a, b = extrema(collect(A))
#         mn = min(mn, a)
#         mx = max(mx, b)
#     end
#     return (mn, mx)
# end
# function global_extrema(arrays)
#     return (minimum(x -> minimum(collect(x)), arrays), maximum(x -> maximum(collect(x)), arrays))
# end
function global_extrema(arrays)
    a = arrays .|> collect .|> extrema
    lim = (minimum(first, a), maximum(last, a))
    return lim
end

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

function dominant_period(t, x)
    N = length(x)                    # Number of data points
    dt = mean(diff(t))                # Approximate time step (assumes uniform spacing)
    
    X = abs2.(FFTW.fft(x))            # Compute power spectrum (magnitude squared)
    freqs = FFTW.fftfreq(N, 1/dt)     # Compute frequency values

    pos_indices = findall(freqs .> 0) # Ignore negative frequencies
    dominant_idx = pos_indices[argmax(X[pos_indices])] # Index of max power

    return 1 / freqs[dominant_idx]    # Return dominant period
end