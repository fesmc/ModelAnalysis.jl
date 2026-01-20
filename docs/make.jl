using Documenter
using ModelAnalysis

makedocs(
    sitename = "ModelAnalysis.jl",
    modules = [ModelAnalysis],
    pages = [
        "Home" => "index.md",
    ],
    warnonly = [:missing_docs],
)

deploydocs(
    repo = "github.com/fesmc/ModelAnalysis.jl.git",
)
