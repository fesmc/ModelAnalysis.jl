using Test
using ModelAnalysis
using NCDatasets
using DataFrames
using Statistics

# ---------------------------------------------------------------------------
# Helpers: build a tiny synthetic ensemble on disk
# ---------------------------------------------------------------------------
"""
    create_subdir(parent, name)

Create a subdirectory `name` inside parent directory `parent` to be used as single ensemble-member directory.
"""
function create_subdir(parent::String, name::String)
    dir = joinpath(parent, name)
    mkpath(dir)
    return dir
end


"""
    fill_member_dir(path_member_dir; nt, value, with_atm=false)

Fill a single ensemble-member directory with files: `timesteps.nc` with a
`time` dimension of length `nt` and a `speed(time)` variable filled with
`value`. Optionally also write `atm.nc` with a `t2m(time)` variable.
"""
function fill_member_dir(path_member_dir::String; nt::Int, value::Float64, with_atm::Bool=false)
    NCDataset(joinpath(path_member_dir, "timesteps.nc"), "c") do ds
        defDim(ds, "time", nt)
        t = defVar(ds, "time", Float64, ("time",))
        t[:] = collect(1.0:nt)
        v = defVar(ds, "speed", Float64, ("time",))
        v[:] = fill(value, nt)
    end

    if with_atm
        NCDataset(joinpath(path_member_dir, "atm.nc"), "c") do ds
            defDim(ds, "time", nt)
            t = defVar(ds, "time", Float64, ("time",))
            t[:] = collect(1.0:nt)
            v = defVar(ds, "t2m", Float64, ("time",))
            v[:] = fill(value * 10, nt)
        end
    end

    return nothing
end


"""
    make_ensemble_dir(parent; rows)

Create an ensemble directory under `parent` with `info.txt` describing the
members in `rows` (a vector of NamedTuples with at least `rundir` and `dx`
fields) and one subdirectory per member.
"""
function make_ensemble_dir(parent::String; rows::Vector{<:NamedTuple})
    
    root = create_subdir(parent, "ens")

    # info.txt: space-separated header, then rows
    open(joinpath(root, "info.txt"), "w") do io
        # Header
        cols = keys(rows[1])
        println(io, join(string.(cols), " "))
        for r in rows
            println(io, join((getfield(r, c) for c in cols), " "))
        end
    end

    n_sim = length(rows)
    for r in rows
        nt = hasproperty(r, :nt) ? r.nt : 4
        with_atm = hasproperty(r, :with_atm) ? r.with_atm : false
        # for single simulations, data is written in top-level directory
        dir = n_sim > 1 ? create_subdir(root, string(r.rundir)) : root
        fill_member_dir(dir; nt=nt, value=Float64(r.value), with_atm=with_atm)
    end

    return root
end

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

@testset "ModelAnalysis" begin

    @testset "Ensemble() empty constructor" begin
        ens = Ensemble()
        @test ens.N == 0
        @test isempty(ens.path)
        @test isempty(ens.v)
        @test ens.w === nothing
    end

    mktempdir() do tmp
        rows = [
            (rundir = "m1", dx = 16, value = 1.0),
            (rundir = "m2", dx = 32, value = 2.0),
            (rundir = "m3", dx = 16, value = 3.0),
        ]
        root = make_ensemble_dir(tmp; rows = rows)

        @testset "Ensemble(path) loads info.txt" begin
            ens = Ensemble(root)
            @test ens.N == 3
            @test length(ens.path) == 3
            @test names(ens.p) == ["rundir", "dx", "value"]
            @test ens.p[!, :dx] == [16, 32, 16]
        end

        @testset "ensemble_get_var! namespaces by filename" begin
            ens = Ensemble(root)
            ensemble_get_var!(ens, "timesteps.nc", "speed")

            @test haskey(ens.v, :timesteps)
            @test haskey(ens.v[:timesteps], :speed)
            @test length(ens.v[:timesteps][:speed]) == 3
            # First member's speed array was filled with 1.0
            @test all(ens.v[:timesteps][:speed][1] .== 1.0)
            @test all(ens.v[:timesteps][:speed][3] .== 3.0)
        end

        @testset "ensemble_get_var! with newname and scale" begin
            ens = Ensemble(root)
            ensemble_get_var!(ens, "timesteps.nc", "speed";
                              newname = "speed_x10", scale = 10.0)

            @test haskey(ens.v[:timesteps], :speed_x10)
            @test all(ens.v[:timesteps][:speed_x10][2] .== 20.0)
        end

        @testset "subset preserves nested v" begin
            ens = Ensemble(root)
            ensemble_get_var!(ens, "timesteps.nc", "speed")

            sub = ModelAnalysis.subset(ens, [1, 3])
            @test sub.N == 2
            @test length(sub.v[:timesteps][:speed]) == 2
            @test all(sub.v[:timesteps][:speed][1] .== 1.0)
            @test all(sub.v[:timesteps][:speed][2] .== 3.0)
            # Original is unchanged
            @test ens.N == 3
            @test length(ens.v[:timesteps][:speed]) == 3
        end

        @testset "filter with predicate" begin
            ens = Ensemble(root)
            ensemble_get_var!(ens, "timesteps.nc", "speed")

            sub = filter(p -> p.dx == 16, ens)
            @test sub.N == 2
            @test length(sub.v[:timesteps][:speed]) == 2
            @test all(sub.v[:timesteps][:speed][1] .== 1.0)
            @test all(sub.v[:timesteps][:speed][2] .== 3.0)
        end

        @testset "sort! reorders members and v entries" begin
            ens = Ensemble(root)
            ensemble_get_var!(ens, "timesteps.nc", "speed")
            ens.w = [10.0, 20.0, 30.0]  # exercises the weights path

            sort!(ens, :value)
            @test ens.p[!, :value] == [1.0, 2.0, 3.0]
            # value was used to fill speed, so first member's speed is still 1.0
            @test all(ens.v[:timesteps][:speed][1] .== 1.0)
            @test ens.w == [10.0, 20.0, 30.0]  # already in order

            # Reverse via explicit permutation
            sort!(ens, [3, 2, 1])
            @test ens.p[!, :value] == [3.0, 2.0, 1.0]
            @test all(ens.v[:timesteps][:speed][1] .== 3.0)
            @test ens.w == [30.0, 20.0, 10.0]
        end

        @testset "ens_stat (vector form) and convenience form" begin
            ens = Ensemble(root)
            ensemble_get_var!(ens, "timesteps.nc", "speed")

            # Vector form: previously crashed (UndefVarError: dat)
            means = ens_stat(ens.v[:timesteps][:speed], mean)
            @test means == [1.0, 2.0, 3.0]

            # Convenience form
            means2 = ens_stat(ens, :timesteps, :speed, mean)
            @test means2 == means
        end

        @testset "ens_map convenience form" begin
            ens = Ensemble(root)
            ensemble_get_var!(ens, "timesteps.nc", "speed")

            doubled = ens_map(ens, :timesteps, :speed, x -> x .* 2)
            @test length(doubled) == 3
            @test all(doubled[2] .== 4.0)
        end

        @testset "multiple domains coexist" begin
            rows2 = [
                (rundir = "m1", dx = 16, value = 1.0, with_atm = true),
                (rundir = "m2", dx = 32, value = 2.0, with_atm = true),
            ]
            root2 = make_ensemble_dir(joinpath(tmp, "sub"); rows = rows2)
            ens = Ensemble(root2)
            ensemble_get_var!(ens, "timesteps.nc", "speed")
            ensemble_get_var!(ens, "atm.nc", "t2m")

            @test haskey(ens.v, :timesteps)
            @test haskey(ens.v, :atm)
            @test all(ens.v[:atm][:t2m][1] .== 10.0)
        end        
    end

    @testset "Load single simulation" begin
        mktempdir() do tmp
            rows = [
                (rundir = "m1", dx = 16, value = 1.0, with_atm = true)
            ]
            root = make_ensemble_dir(tmp; rows = rows)
            ens = Ensemble(root)
            @test ens.N == 1
            
            ensemble_get_var!(ens, "atm.nc", "t2m")
            @test !isnothing(ens.v[:atm][:t2m][1])
        end
    end
end
