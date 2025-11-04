# Dependencies: Interpolations, DSP, ImageFiltering, CairoMakie

"""
    lowpass_irregular(x, y; period_cutoff, dt_target=nothing, method=:butter, order=4)

Smooths an unevenly spaced time series `(x, y)` by applying a low-pass filter
that retains only variability with period longer than `period_cutoff`.

If `x` is unevenly spaced, the function first interpolates to an even grid,
applies the chosen filter, and then interpolates back.

# Arguments
- `x::AbstractVector`: independent variable (e.g., time)
- `y::AbstractVector`: dependent variable (e.g., temperature)

# Keyword Arguments
- `period_cutoff::Real`: minimum period (in same units as `x`) to retain
- `dt_target::Real`: target spacing for interpolation (default = median spacing)
- `method::Symbol`: filtering method, one of:
  - `:butter` → Butterworth low-pass filter (default)
  - `:gaussian` → Gaussian smoothing kernel
- `order::Int`: order of Butterworth filter (ignored if `method=:gaussian`)
- `plot::Bool`: if `true`, shows a plot comparing original and smoothed series

# Returns
A named tuple:
`(y_smooth, x_even, y_even_smooth)`

# Example
```julia
x = sort!(rand(200) .* 120)          # kyr
y = sin.(2π .* x ./ 25) .+ 0.3randn(length(x))

result = lowpass_irregular(x, y; period_cutoff=9.0, method=:butter, plot=true)
"""
function lowpass_irregular(x::AbstractVector, y::AbstractVector;
period_cutoff::Real,
dt_target::Union{Nothing,Real}=nothing,
method::Symbol=:butter,
order::Int=4,
plot::Bool=false)

# Ensure sorted input
p = sortperm(x)
x, y = x[p], y[p]

# Determine target spacing
dt = isnothing(dt_target) ? median(diff(x)) : dt_target

# --- Step 1: Interpolate to uniform grid
x_even = range(first(x), last(x), step=dt)
itp = Interpolations.interpolate((x,), y, Interpolations.Gridded(Interpolations.Linear()))
y_even = itp.(x_even)

# --- Step 2: Apply smoothing
if method == :butter
    fs = 1 / dt
    f_cutoff = 1 / period_cutoff
    norm_cutoff = f_cutoff / (fs / 2)
    b = DSP.butter(order, norm_cutoff, DSP.Lowpass())
    y_even_smooth = DSP.filtfilt(b, y_even)

elseif method == :gaussian
    σ = (period_cutoff / dt) / 2
    y_even_smooth = ImageFiltering.imfilter(y_even, ImageFiltering.Kernel.gaussian(σ))

else
    error("Unknown method: $method. Choose :butter or :gaussian.")
end

# --- Step 3: Interpolate back to original x
itp_back = Interpolations.interpolate((x_even,), y_even_smooth,
                                      Interpolations.Gridded(Interpolations.Linear()))
y_smooth = itp_back.(x)

# --- Optional Plot
if plot
    CairoMakie.figure()
    CairoMakie.lines(x, y; color=:gray, alpha=0.4, label="original")
    CairoMakie.lines(x, y_smooth; color=:red, linewidth=2, label="smoothed")
    CairoMakie.axislegend()
    CairoMakie.current_figure()
end

return (y_smooth=y_smooth, x_even=x_even, y_even_smooth=y_even_smooth)
end
