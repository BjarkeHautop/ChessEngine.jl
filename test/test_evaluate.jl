using ChessEngine
using Test

@testset "Evaluation" begin
    # Starting position should be balanced
    b = start_position()
    @test evaluate(b) == 0

    m1 = Move("e2", "e4")
    make_move!(b, m1)
    M2 = Move("d7", "d5")
    make_move!(b, M2)

    @test evaluate(b) == 0

    M3 = Move("e4", "d5"; capture = B_PAWN)
    make_move!(b, M3)
    @test evaluate(b) > 100

    M4 = Move("d8", "d5"; capture = W_PAWN)
    make_move!(b, M4)
    @test evaluate(b) < 100
end

@testset "Search Finds Scholar Mate" begin
    b = start_position()
    moves = [Move("f2", "f3"), Move("e7", "e5"), Move("g2", "g4")]

    for m in moves
        make_move!(b, m)
    end
    score, mv = search(b, 2)
    @test score < -10_000  # Checkmate 
    @test mv == Move("d8", "h4")
end

@testset "Search depth 1 takes pawn" begin
    b = start_position()

    m1 = Move("e2", "e4")
    make_move!(b, m1)
    M2 = Move("d7", "d5")
    make_move!(b, M2)

    score, mv = search(b, 1; opening_book = false)
    @test mv == Move("e4", "d5"; capture = B_PAWN)
end

@testset "Opening trap" begin
    b = start_position()
    moves = [
        Move("e2", "e4"),
        Move("e7", "e5"),
        Move("g1", "f3"),
        Move("b8", "c6"),
        Move("f1", "b5"),
        Move("a7", "a6"),
        Move("b5", "a4"),
        Move("d7", "d6"),
        Move("d2", "d4"),
        Move("b7", "b5"),
        Move("a4", "b3"),
        Move("c6", "d4"; capture = W_PAWN),
        Move("f3", "d4"; capture = B_KNIGHT),
        Move("e5", "d4", capture = W_KNIGHT)
    ]

    for m in moves
        make_move!(b, m)
    end
    score_blunder, mv_blunder = search(b, 2; opening_book = false) # Low depth should miss the tactic
    @test mv_blunder == Move("d1", "d4"; capture = B_PAWN)

    make_move!(b, Move("d1", "d4"; capture = B_PAWN))
    make_move!(b, Move("c7", "c5"))
    make_move!(b, Move("d4", "d5"))
    make_move!(b, Move("c8", "e6"))
    make_move!(b, Move("d5", "c6"))
    score_after, mv_after = search(b, 5; opening_book = false) # Black should be better
    @test score_after < 0
    @test mv_after == Move("e6", "d7")
end