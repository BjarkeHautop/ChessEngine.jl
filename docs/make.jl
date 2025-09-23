using ChessEngine
using Documenter

DocMeta.setdocmeta!(ChessEngine, :DocTestSetup, :(using ChessEngine); recursive = true)

makedocs(;
    modules = [ChessEngine],
    authors = "Bjarke Hautop <bjarke.hautop@gmail.com> and contributors",
    sitename = "ChessEngine.jl",
    format = Documenter.HTML(;
        canonical = "https://BjarkeHautop.github.io/ChessEngine.jl",
        edit_link = "main",
        assets = String[]
    ),
    pages = [
        "Home" => "index.md",
        "Getting Started" => "starting.md",
        "API" => "api.md"
    ]
)

deploydocs(;
    repo = "github.com/BjarkeHautop/ChessEngine.jl",
    devbranch = "main"
)
