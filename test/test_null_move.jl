using ChessEngine
using Test

@testset "Null move tests" begin
    b = Board()
    b_copy = deepcopy(b)

    ChessEngine.make_null_move!(b)
    @test b.side_to_move == BLACK
    @test b.halfmove_clock == 1

    ChessEngine.unmake_null_move!(b)
    @test b.side_to_move == WHITE
    @test b.halfmove_clock == 0

    @test ChessEngine.position_equal(b, b_copy)
end
