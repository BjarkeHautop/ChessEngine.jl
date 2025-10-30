using OrbisChessEngine
using Test

@testset "Evaluation" begin
    # Starting position should be balanced
    b = Board()
    @test evaluate(b) == 0

    m1 = Move("e2", "e4")
    make_move!(b, m1)
    M2 = Move("d7", "d5")
    make_move!(b, M2)

    @test evaluate(b) == 0

    M3 = Move("e4", "d5"; capture = Piece.B_PAWN)
    make_move!(b, M3)
    @test evaluate(b) > 100

    M4 = Move("d8", "d5"; capture = Piece.W_PAWN)
    make_move!(b, M4)
    @test evaluate(b) < 100
end
