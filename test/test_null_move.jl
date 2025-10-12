using OrbisChessEngine
using Test

@testset "Null move tests" begin
    b = Board()
    b_copy = deepcopy(b)

    OrbisChessEngine.make_null_move!(b)
    @test b.side_to_move == BLACK
    @test b.halfmove_clock == 1

    OrbisChessEngine.undo_null_move!(b)
    @test b.side_to_move == WHITE
    @test b.halfmove_clock == 0

    @test OrbisChessEngine.position_equal(b, b_copy)
    @test b == b_copy
end
