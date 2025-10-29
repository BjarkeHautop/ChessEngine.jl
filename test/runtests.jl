using OrbisChessEngine
using Test

function include_tests(; include_aqua::Bool = false)
    folder = @__DIR__

    # Get all .jl files except this script itself
    this_file = basename(@__FILE__)
    files = sort(filter(f -> endswith(f, ".jl") && f != this_file, readdir(folder)))

    for file in files
        if file == "test_aqua.jl"
            include_aqua && include(joinpath(folder, file))
        else
            include(joinpath(folder, file))
        end
    end
end

include_tests(; include_aqua = true)
