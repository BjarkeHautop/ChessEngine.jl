using ChessEngine
using Test

@testset "Search Finds Scholar Mate" begin
    b = start_position()
    moves = [Move("f2", "f3"), Move("e7", "e5"), Move("g2", "g4")]

    for m in moves
        make_move!(b, m)
    end
    score, mv = search(b, 2; opening_book = false)
    @test score < -10_000  # Checkmate 
    @test mv == Move("d8", "h4")
end

@testset "Search with time constraint" begin
    b = start_position()

    m1 = Move("e2", "e4")
    make_move!(b, m1)
    M2 = Move("d7", "d5")
    make_move!(b, M2)

    time_before = time_ns() ÷ 1_000_000
    score, mv = search(b, 10; opening_book = false, time_budget = 1000)
    time_after = time_ns() ÷ 1_000_000
    @test (time_after - time_before) <= 1500  # Allow some overhead
end

@testset "Search verbose works" begin
    b = start_position()

    score, mv = search(b, 2; opening_book = false, verbose = true)
    @test mv !== nothing
end

@testset "Search works in random position" begin
    b = board_from_fen("rnbq1rk1/pp4bp/2pp1np1/3Ppp2/2P5/2N2NP1/PP2PPBP/R1BQ1RK1 w KQkq e6 0 1")

    score, mv = search(b, 4; opening_book = false)
    @test true  # Just ensure it completes without error
end