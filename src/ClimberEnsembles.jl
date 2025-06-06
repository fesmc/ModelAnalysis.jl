
module ClimberEnsembles

import DataFrames 
import PrettyTables
import CSV

using JLD2
using YAXArrays
using NetCDF
using Statistics

using ..Ensembles

export ClimberModel
export ClimberEnsemble
export ensemble_get_var!

Base.@kwdef mutable struct ClimberModel <: Ensembles.AbstractModel
    path::String = ""
    p::DataFrames.DataFrame = DataFrames.DataFrame()    # info/parameters
    atm::Dict{Union{String,Symbol},Any} = Dict()        # variables, preferrably YAXArrays or Vector{YAXArray}
    ocn::Dict{Union{String,Symbol},Any} = Dict()        # ...
    lnd::Dict{Union{String,Symbol},Any} = Dict()
    geo::Dict{Union{String,Symbol},Any} = Dict()
    cmn::Dict{Union{String,Symbol},Any} = Dict()
    sic::Dict{Union{String,Symbol},Any} = Dict()
    ice::Dict{Union{String,Symbol},Any} = Dict()
    bgc::Dict{Union{String,Symbol},Any} = Dict()

    atm_ts::Dict{Union{String,Symbol},Any} = Dict()
    ocn_ts::Dict{Union{String,Symbol},Any} = Dict()
    lnd_ts::Dict{Union{String,Symbol},Any} = Dict()
    geo_ts::Dict{Union{String,Symbol},Any} = Dict()
    cmn_ts::Dict{Union{String,Symbol},Any} = Dict()
    sic_ts::Dict{Union{String,Symbol},Any} = Dict()
    ice_ts::Dict{Union{String,Symbol},Any} = Dict()
    bgc_ts::Dict{Union{String,Symbol},Any} = Dict()
end

mutable struct ClimberEnsemble <: Ensembles.AbstractEnsemble
    N::Integer
    path::Vector{String}                        # member path (path to each member of ensemble)
    set::Vector{Integer}                        # which set did member come from (corresponding to ensemble base paths)
    p::DataFrames.DataFrame                     # info/parameters
    s::DataFrames.DataFrame                     # styles
    w::Union{Array,Ensembles.AbstractEnsembleWeights}     # Ensemble weights

    # variables, preferrably each variable a YAXArray with one dimension N,
    # or a vector of length N of YAXArrays
    v::Dict{Union{String,Symbol},Any}

    # vector of individual "ensemble members" defined by the ClimberModel struct
    #m::Vector{ClimberModel}
    m::ClimberModel
end

function ClimberEnsemble(ens_path::String;sort_by::String="")   
    
    N, path, set, p, s = ensemble_init(ens_path;sort_by=sort_by)

    # Instantiate climber models
    #m = [ClimberModel(path=p) for p in path]
    m = ClimberModel()

    # Store all information for output in the ensemble object
    ens = ClimberEnsemble(N,path,set,p,s,Vector(),Dict(),m)

    return ens
end

function ClimberEnsemble(ens_paths::Vector{String};sort_by::String="")   
    
    N, path, set, p, s = ensemble_init(ens_paths;sort_by=sort_by)

    # Instantiate climber models
    #m = [ClimberModel(path=p) for p in path]
    m = ClimberModel()

    # Store all information for output in the ensemble object
    ens = ClimberEnsemble(N,path,set,p,s,Vector(),Dict(),m)

    return ens
end

function ensemble_get_var!(ens::ClimberEnsemble,filename::String,varname::String;newname=nothing,scale=1.0)

    # Set how the variable will be saved
    if isnothing(newname) 
        newname = varname
    end
    
    # Determine domain to save in based on filename
    domainname, _ = splitext(basename(filename))

    # Load the vector of ensemble data
    vars = ensemble_get_var(ens.path,filename,varname;newname)
    
    # # Store variables in climber models
    # for q in 1:ens.N
    #     ens.m[q].(domainname)[newname] = vars[q]
    # end
    # Store variables in climber model
    ens.m.(domainname)[newname] = vars

    return
end

end # module