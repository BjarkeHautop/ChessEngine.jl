using OrbisChessEngine
using Documenter

DocMeta.setdocmeta!(OrbisChessEngine, :DocTestSetup, :(using OrbisChessEngine); recursive = true)

makedocs(;
    modules = [OrbisChessEngine],
    authors = "Bjarke Hautop <bjarke.hautop@gmail.com> and contributors",
    sitename = "OrbisChessEngine.jl",
    format = Documenter.HTML(;
        canonical = "https://BjarkeHautop.github.io/OrbisChessEngine.jl",
        edit_link = "main",
        assets = String[]
    ),
    pages = [
        "Home" => "index.md",
        "Getting Started" => "starting.md",
        "Performance Benchmarks" => "benchmarks.md",
        "Reference" => "reference.md",
        "Developers" => "developers.md"
    ]
)

deploydocs(;
    repo = "github.com/BjarkeHautop/OrbisChessEngine.jl",
    devbranch = "main"
)
