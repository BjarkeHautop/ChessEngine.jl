using OrbisChessEngine
using Test

# Takes 10 sec for depth 5 on my machine
@testset "perft tests" begin
    b = Board()
    @test perft(b, 0) == 1
    @test perft(b, 1) == 20
    @test perft(b, 2) == 400
    @test perft(b, 3) == 8902
    @test perft(b, 4) == 197281
    @test perft(b, 5) == 4865609
end

# Takes 5 sec for depth 5 on my machine
@testset "fast perft tests" begin
    b = Board()
    @test perft_fast(b, 0) == 1
    @test perft_fast(b, 1) == 20
    @test perft_fast(b, 2) == 400
    @test perft_fast(b, 3) == 8902
    @test perft_fast(b, 4) == 197281
    @test perft_fast(b, 5) == 4865609
end