#### Functions related to testing specific things 

function ensemble_check(path::String; vars = nothing)

    # Load ensemble information
    ens = Ensemble(path);

    # Initially only loading standard PD comparison statistics variables
    var_names = ["time","rmse_H","rmse_zsrf","rmse_uxy","rmse_uxy_log"];

    # Add any other variables of interest from arguments
    if vars != nothing
        push!(var_names,vars);
    end 

    # Loop over all variable names of interest
    # (should be 1D time series, for now!)
    for vname in var_names
        ensemble_get_var!(ens,"yelmo2D.nc",vname);
    end

    # Generate a dataframe to hold output information in pretty format 
    df = DataFrames.DataFrame(runid = ens.p[!,:runid]);

    for vname in var_names
        #print(vname,size(ens.v[vname]),"\n")
        if ndims(ens.v[vname]) == 1
            v = [ens.v[vname][i][end] for i in 1:length(ens.v[vname])];
            DataFrames.insertcols!(df, vname => v )
        else
            print("ensemble_check:: Error: this function should be used with time series variables")
            print("vname = ", vname)
            return
        end
    end

    # Print information to screen, first about
    # ensemble (info) and then variables of interest.

    PrettyTables.pretty_table(ens.p, header = names(ens.p), crop = :horizontal)
    PrettyTables.pretty_table(df, header = names(df), crop = :horizontal)

    return ens
end
