using ChessEngine
using Test

@testset "Null move tests" begin
    b = start_position()
    b_copy = deepcopy(b)

    make_null_move!(b)
    @test b.side_to_move == BLACK
    @test b.halfmove_clock == 1

    unmake_null_move!(b)
    @test b.side_to_move == WHITE
    @test b.halfmove_clock == 0

    @test position_equal(b, b_copy)
end