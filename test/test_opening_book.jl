using ChessEngine
using Test

@testset "Doesn't use opening book in endgame" begin
    b = Board(fen = "4k3/8/8/8/8/8/4P3/4K3 w - - 0 1")
    time_before = time_ns() ÷ 1_000_000
    result = search(b, 10; opening_book = KOMODO_OPENING_BOOK)
    time_after = time_ns() ÷ 1_000_000
    # Test some time has elapsed

    @test (time_after - time_before) > 0
end

@testset "Opening book provides move in starting position" begin
    b = Board()
    result = search(b, 1; opening_book = KOMODO_OPENING_BOOK)
    @test result.from_book == true
    @test result.move !== nothing
end

@testset "has_pawn_for_en_passant function" begin
    b = Board()
    make_move!(b, Move("e2", "e5"))
    make_move!(b, Move("d7", "d5"))

    @test ChessEngine.has_pawn_for_en_passant(b, 3) == true
    make_move!(b, Move("a2", "a3"))
    @test ChessEngine.has_pawn_for_en_passant(b, 3) == false
    make_move!(b, Move("d5", "d4"))
    make_move!(b, Move("c2", "c4"))
    @test ChessEngine.has_pawn_for_en_passant(b, 2) == true
end
