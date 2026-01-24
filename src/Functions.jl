
"""
    MissingToNaN(dat)

Convert `missing` values in an array-like object to `NaN`. Most importantly,
ensures that `missing` is removed from the eltype of the array too.

The input is first converted to floating-point type element-wise, and all
`missing` values are replaced with `NaN` using `coalesce`.

# Arguments
- `dat`: Array-like object containing numeric values and possibly `missing`.

# Returns
An array of floating-point values where all `missing` entries have been
replaced by `NaN`.

# Notes
- All elements are converted to floating-point using `float.(dat)`.
- This function allocates a new array and does not modify the input in place.
- Non-numeric values will result in a conversion error.

# Examples
```julia
dat = [1.0, missing, 3.5]
clean = MissingToNaN(dat)
```
"""
function MissingToNaN(dat)
    dat = float.(dat)
    dat = coalesce.(dat,NaN)
    return dat
end

"""
    clean(var; mask=nothing, zrange=nothing, scale=identity, outlier_value=NaN)

Clean and post-process an array-like variable.

The function performs the following operations in order:

1. Convert all `missing` values in `var` to `NaN`.
2. Apply an optional boolean mask, setting values outside the mask to `NaN`.
3. Enforce a value range (`zrange`), either clipping values to the range
   or replacing out-of-range values with a specified `outlier_value`.
4. Apply a scaling function element-wise.

# Arguments
- `var`: Array-like numeric variable to be cleaned.

# Keyword Arguments
- `mask`: Boolean array of the same shape as `var`. Entries where `mask == false`
  are set to `NaN`. If `nothing`, no mask is applied.
- `zrange`: Tuple `(zmin, zmax)` specifying the allowed value range.
  If `nothing`, the range is inferred from the non-`NaN` values of `var`.
- `scale`: Function applied element-wise to the cleaned variable
  (default: `identity`).
- `outlier_value`: Controls how values outside `zrange` are handled:
    - `nothing`: values are clipped to `zrange`
    - scalar: all out-of-range values are set to this value
    - two-element vector or tuple: values below `zmin` are set to
      `outlier_value[1]`, and values above `zmax` to `outlier_value[2]`
  (default: `NaN`).

# Returns
A copy of `var` with missing values converted to `NaN`, masking and range
handling applied, and scaled as requested.

# Notes
- The input `var` is not modified in place.
- Range limits are computed from `var` (not the masked array) when
  `zrange === nothing`.
"""
function clean(var; mask = nothing, zrange = nothing, scale = identity, outlier_value = NaN)
    
    # Copy to a new variable
    myvar = deepcopy(var)

    # Convert all missing to NaN for consistency
    myvar = MissingToNaN(var)

    # mask:
    if !isnothing(mask)
        myvar[ mask .== false ] .= NaN
    end

    # zrange:
    if isnothing(zrange)
        zrange = extrema(myvar[.!isnan.(myvar)])
    end

    # Limit the variable range to desired range (zrange or outlier_value)
    if isnothing(outlier_value)
        myvar[myvar .< zrange[1]] .= zrange[1]
        myvar[myvar .> zrange[2]] .= zrange[2]
    else
        if length(outlier_value)==1
            myvar[myvar .< zrange[1]] .= outlier_value
            myvar[myvar .> zrange[2]] .= outlier_value
        else
            myvar[myvar .< zrange[1]] .= outlier_value[1]
            myvar[myvar .> zrange[2]] .= outlier_value[2]
        end
    end
    
    # Scale variable as needed:
    myvar = scale.(myvar);

    return myvar
end 

### DataFrames

"""
    print_row(row; sep = "")

Pretty-print the contents of a table row as two columns aligned as `name   value` pairs.

Each column name and its corresponding value are printed on a separate line,
with the column name left-aligned to a fixed width for readability.

# Arguments
- `row`: A table row supporting `names(row)` and iteration over values
  (e.g. a `DataFrameRow`).

# Keyword Arguments
- `sep`: Optional separator inserted between the column name and value.
  If non-empty, it is surrounded by single spaces on both sides
  (e.g. `sep=":"` prints `"name : value"`). Default is no separator.

# Output
Prints formatted lines to standard output; nothing is returned.

# Notes
- Column names are padded to a width of 20 characters using `rpad`.
- The function assumes that `names(row)` and iteration over `row` are ordered
  consistently.

# Examples
```julia
using DataFrames

df = DataFrame(a = 1, long_name = 2.5)
print_row(df[1, :]; sep="=")
```
"""
function print_row(row;sep="")
    if sep != ""
        sep = " "*sep*" "
    end
    for (name, val) in zip(names(row), row)
        println(rpad(name, 20), sep, val)
    end
end

##################

"""
    global_extrema(arrays)

Compute the global minimum and maximum over multiple arrays.

For each array in `arrays`, the local extrema are computed using `extrema`.
The overall minimum of all minima and the overall maximum of all maxima
are then returned.

# Arguments
- `arrays`: An iterable of array-like objects containing numeric values.

# Returns
A tuple `(min, max)` giving the global extrema across all input arrays.

# Notes
- Each element of `arrays` is first collected before calling `extrema`,
  allowing generators and other lazy iterables to be used as input.
- All arrays must contain at least one element and support `extrema`.

# Examples
```julia
a = [1, 2, 3]
b = [-5, 0, 4]

lims = global_extrema((a, b))
# returns (-5, 4)
```
"""
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