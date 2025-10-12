using OrbisChessEngine
using Test

# Takes 4 sec for depth 5 on my machine
@testset "perft tests" begin
    b = Board()
    @test perft(b, 0) == 1
    @test perft(b, 1) == 20
    @test perft(b, 2) == 400
    @test perft(b, 3) == 8902
    @test perft(b, 4) == 197_281
    @test perft(b, 5) == 4_865_609
end

# Takes 1 sec for depth 5 on my machine
@testset "fast perft tests" begin
    b = Board()
    @test perft_fast(b, 0) == 1
    @test perft_fast(b, 1) == 20
    @test perft_fast(b, 2) == 400
    @test perft_fast(b, 3) == 8902
    @test perft_fast(b, 4) == 197_281
    @test perft_fast(b, 5) == 4_865_609
    # @test OrbisChessEngine.perft_superfast(b, 6) == 119_060_324
    # @test OrbisChessEngine.perft_superfast(b, 7) == 3_195_901_860
end

@testset "perft divide tests" begin
    b = Board()
    result = OrbisChessEngine.perft_divide(b, 1)
    @test result == 20
end

