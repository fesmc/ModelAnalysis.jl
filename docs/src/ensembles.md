# Ensemble

The `Ensemble` type provides a structured container for managing ensembles of model simulations. Each ensemble may consist of input parameters, output variables, styling metadata, model objects, and optional ensemble weights.

## Type Definition

```julia
mutable struct Ensemble <: AbstractEnsemble
    N::Integer
    path::Vector{String}
    mpath::Vector{String}
    set::Vector{Integer}
    p::DataFrames.DataFrame
    s::DataFrames.DataFrame
    w::Union{Array,AbstractEnsembleWeights}
    v::Dict{Union{String,Symbol},Any}
    m::Vector{AbstractModel}
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
ens.path = ["./ensemble1"]
ens.mpath = ["./ensemble1/member1", "./ensemble1/member2", ...]
ens.set = fill(1, ens.N)
ens.p = DataFrame(param1 = rand(ens.N), param2 = rand(ens.N))
ens.s = DataFrame(color = ["red", "blue", ...])
ens.v[:temperature] = [temp1, temp2, ...]  # YAXArrays
ens.m = [model1, model2, ...]              # AbstractModel instances
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

* `sort_by::String`: Sort members using a column from the parameter `DataFrame`.

These constructors initialize the following fields:

* `N`, `path`, `mpath`, `set`, `p`, `s`

Remaining fields (`w`, `v`, `m`) can be filled in later.

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
# Load ensemble from path
ens = Ensemble("runs/experiment1")

# Add variables and models
ens.v[:smb] = load_smb_outputs(ens.mpath)
ens.m = [load_model(mpath) for mpath in ens.mpath]

# Save to file
ensemble_save("output/ensemble_exp1.jld2", ens, "ens")
```

---

## Notes

* Variables (`v`) are expected to be `YAXArray`s or collections thereof.
* Weights (`w`) may be an array or a custom `AbstractEnsembleWeights`.
* The type `AbstractModel` must be defined elsewhere in your codebase to suit your model structure.

---
