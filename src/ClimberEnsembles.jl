
module ClimberEnsembles

import DataFrames 
import PrettyTables
import CSV

using JLD2
using YAXArrays
using NetCDF
using Statistics

include("Ensembles.jl")
using .Ensembles

Base.@kwdef mutable struct ClimberModel <: AbstractModel
    path::String = ""
    p::DataFrames.DataFrame = DataFrame()               # info/parameters
    atm::Dict{Union{String,Symbol},Any} = Dict()        # variables, preferrably YAXArrays or Vector{YAXArray}
    ocn::Dict{Union{String,Symbol},Any} = Dict()        # ...
    lnd::Dict{Union{String,Symbol},Any} = Dict()
    geo::Dict{Union{String,Symbol},Any} = Dict()
    cmn::Dict{Union{String,Symbol},Any} = Dict()
    sic::Dict{Union{String,Symbol},Any} = Dict()
    ice::Dict{Union{String,Symbol},Any} = Dict()
    bgc::Dict{Union{String,Symbol},Any} = Dict()
end

mutable struct ClimberEnsemble <: AbstractEnsemble
    N::Integer
    path::Vector{String}                        # ensemble base path(s)
    mpath::Vector{String}                       # member path (path to each member of ensemble)
    set::Vector{Integer}                        # which set did member come from (corresponding to ensemble base paths)
    p::DataFrames.DataFrame                     # info/parameters
    s::DataFrames.DataFrame                     # styles
    w::Union{Array,AbstractEnsembleWeights}     # Ensemble weights

    # variables, preferrably each variable a YAXArray with one dimension N,
    # or a vector of length N of YAXArrays
    v::Dict{Union{String,Symbol},Any}

    # vector of individual "ensemble members" defined by the ClimberModel struct
    m::Vector{ClimberModel}

end

function ClimberEnsemble(ens_path::String;sort_by::String="")   
    
    N, path, mpath, set, p, s = ensemble_init(ens_path;sort_by=sort_by)

    # Instantiate climber models
    m = [ClimberModel(path=mp) for mp in mpath]
    
    # Store all information for output in the ensemble object
    ens = ClimberEnsemble(N,path,mpath,set,p,s,Vector(),Dict(),m)

    return ens
end

function ClimberEnsemble(ens_paths::Vector{String};sort_by::String="")   
    
    N, path, mpath, set, p, s = ensemble_init(ens_paths;sort_by=sort_by)

    # Instantiate climber models
    m = [ClimberModel(path=mp) for mp in mpath]

    # Store all information for output in the ensemble object
    ens = ClimberEnsemble(N,path,mpath,set,p,s,Vector(),Dict(),m)

    return ens
end


end # module