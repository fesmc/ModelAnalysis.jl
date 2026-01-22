# Ensemble

The `Ensemble` type provides a structured container for managing ensembles of model simulations. Each ensemble may consist of input parameters, styling metadata, ensemble variables and optional ensemble weights.

## Type Definition

```julia
mutable struct Ensemble <: AbstractEnsemble
    N::Integer
    path::Vector{String}
    set::Vector{Integer}
    p::DataFrames.DataFrame
    s::DataFrames.DataFrame
    w::Union{Array,AbstractEnsembleWeights}
    v::Dict{Union{String,Symbol},Any}
end
```

---

## Creating an Ensemble

### Manual Construction

To construct an ensemble manually:

```julia
ens = Ensemble()

# Populate fields
ens.N = 10
ens.path = ["./ensemble1/member1", "./ensemble1/member2", ...]
ens.set = fill(1, ens.N)
ens.p = DataFrame(param1 = rand(ens.N), param2 = rand(ens.N))
ens.s = DataFrame(color = ["red", "blue", ...])
ens.w = fill(1, ens.N) # Vector of weights for each ensemble member
ens.v[:temperature] = [temp1, temp2, ...]  # Vector of YAXArrays
```

This method gives you full control and is suitable for dynamically generated ensembles.

---

### From Directory Path

You can also load ensembles automatically using a directory path or a list of paths:

```julia
ens = Ensemble("path/to/ensemble1")
ens = Ensemble(["path/to/ens2a", "path/to/ens2b"])
```

#### Optional Keyword Arguments

* `sort_by`: Sort members using a column from the parameter `DataFrame`.

These constructors initialize the following fields:

* `N`, `path`, `set`, `p`, `s`

Remaining fields (`w`, `v`) can be filled in later.

---

## Saving an Ensemble

To save an ensemble to a JLD2 file:

```julia
ensemble_save("output_file.jld2", ens, "ens")
```

* `output_file.jld2`: Target file name.
* `ens`: The ensemble to be saved.
* `"ens"`: Key under which to store the ensemble in the file.

> Uses `JLD2.jldopen` internally.

---

## Example Workflow

```julia
# Initialize an ensemble from path
ens = Ensemble("runs/experiment1")

# Add variables
ensemble_get_var!(ens,"lnd.nc","smb")
ensemble_get_var!(ens,"atm.nc","t2m",newname="t2m_atm")

# Save to file
ensemble_save("output/ensemble_exp1.jld2", ens, "ens")
```

---

## Notes

* Variables (`v`) are expected to be `YAXArray`s or collections thereof.
* Weights (`w`) may be a vector, array or a custom `AbstractEnsembleWeights`.

---

## Working with Ensembles: a basic workflow

This example demonstrates a typical workflow when working with **ensembles** in `ModelAnalysis.jl`: loading an ensemble from disk, attaching parameter metadata, loading model output variables, and creating subsets for analysis.

The intent is to show *patterns* rather than a single use case, so you can adapt the same steps to different ensembles, parameters, and diagnostics.

---

### 1. Defining an ensemble

An ensemble is usually defined by a directory that contains multiple model realizations (members). Each member corresponds to one model run, typically with different parameters or forcings.

```julia
# Load an ensemble from a directory
ens = Ensemble(info.fldr)
```

At this point, the following information has been initialized:

* `ens.N` is the number of ensemble members
* `ens.path` stores the paths to each member
* `ens.p` is a DataFrame holding parameters and metadata
* `ens.s` is a DataFrame that can hold useful information for styles when plotting

---

### 2. Attaching parameter metadata

Often, parameters are known externally (e.g. from a design table or configuration file) and should be attached to the ensemble after loading.

Here, we add two parameters:

* `omp`: number of OpenMP threads used in the run
* `dx`: horizontal grid spacing

```julia
ens.p[!, :omp] = info.omp
ens.p[!, :dx]  = info.dx
```

This makes the parameters first-class ensemble metadata and enables sorting, filtering, and grouping operations later on.

---

### 3. Loading variables from model output

Model output is typically stored in NetCDF files inside each ensemble member directory. So far, there is only one specialized routine for loading ensemble variables, which is done via `ensemble_get_var!`.

```julia
ensemble_get_var!(ens, "timesteps.nc", "speed")
ensemble_get_var!(ens, "timesteps.nc", "dt_now")
```

After this step:

* `ens.v[:speed]` contains the variable `speed` used in each run
* `ens.v[:dt_now]` contains the variable `dt_now` used in each run

The exact structure (scalars, vectors, arrays) depends on the variable stored in the NetCDF file. But each member of `ens.v` is expected to be a vector of length `ens.N`, so one entry per ensemble member.

---

### 4. Sorting an ensemble

Ensembles can be sorted by any parameter or derived quantity stored in `ens.p`.

```julia
ens = sort!(ens, :dx)
```

This is useful for visualization and for creating ordered subsets (e.g. from coarse to fine resolution).

---

### 5. Creating subsets

There are several equivalent ways to create subsets of an ensemble, depending on what is most readable or convenient.

#### 5.1 Subsetting by parameter values

Select all ensemble members with a grid spacing of `dx = 16`:

```julia
ens1 = ModelAnalysis.subset(ens, findall(ens.p[!, :dx] .== 16))
```

This approach is explicit and flexible when you need full control over the index selection.

---

#### 5.2 Subsetting by index range

Select the first three ensemble members:

```julia
ens2 = ModelAnalysis.subset(ens, [1:3...])
```

This is mainly useful after sorting, when the ordering itself is meaningful.

---

#### 5.3 Filtering with a predicate

For more expressive, parameter-based selection, you can use `filter` with a predicate function:

```julia
ens3 = filter(p -> p.dx == 16, ens)
```

This style is often the most readable and scales well when multiple conditions are involved, for example:

```julia
ens_fine = filter(p -> p.dx ≤ 16 && p.omp ≥ 8, ens)
```

---

### 6. Summary

A typical ensemble analysis workflow therefore looks like:

1. Load ensemble structure from disk
2. Load variables from model output
3. Sort and subset the ensemble as needed
4. Perform analysis or visualization on selected subsets

This separation between *structure*, *metadata*, and *data* is deliberate and helps keep ensemble analyses reproducible and easy to extend.
