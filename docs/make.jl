using Documenter
using ModelAnalysis

makedocs(
    sitename = "ModelAnalysis.jl",
    modules = [ModelAnalysis],
    pages = [
        "Home" => "index.md",
        "Ensembles" => "ensembles.md",
        "Plotting with Makie" => "plotting-with-makie.md",
        "API" => "modelanalysis-api.md"
    ],
    warnonly = [:missing_docs],
)

deploydocs(
    repo = "github.com/fesmc/ModelAnalysis.jl.git",
)
