using ChessEngine
using Test
using Aqua

@testset "ChessEngine.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(ChessEngine)
    end
    # Write your tests here.
end
