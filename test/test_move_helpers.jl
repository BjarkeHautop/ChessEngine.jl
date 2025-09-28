using ChessEngine
using Test

@testset "ChessEngine.king_square / ChessEngine.square_attacked / in_check" begin
    b = Board()

    # --- ChessEngine.king_square ---
    @test ChessEngine.king_square(b, WHITE) == ChessEngine.square_index(5, 1)   # e1
    @test ChessEngine.king_square(b, BLACK) == ChessEngine.square_index(5, 8)   # e8

    # --- ChessEngine.square_attacked by pawns ---
    make_move!(b, Move("e2", "e4"))
    # Check d5 square is attacked by e4 pawn
    @test ChessEngine.square_attacked(b, ChessEngine.square_index(4, 5), WHITE)    # d5 attacked
    # Check d6 square is not attacked 
    @test !ChessEngine.square_attacked(b, ChessEngine.square_index(4, 6), WHITE)   # d6 not attacked

    # --- in_check ---
    @test !in_check(b, WHITE)
    @test !in_check(b, BLACK)

    # Move black quuen to e3 to check white king
    make_move!(b, Move("d8", "e3"))
    @test in_check(b, WHITE)
end
