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

@testset "Search works in random position" begin
    b = board_from_fen("rnbq1rk1/pp4bp/2pp1np1/3Ppp2/2P5/2N2NP1/PP2PPBP/R1BQ1RK1 w KQkq e6 0 1")

    score, mv = search(b, 5; opening_book = false)
    @test true  # Just ensure it completes without error
end