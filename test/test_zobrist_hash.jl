using ChessEngine
using Test

@testset "zobrist_hash" begin
    b = start_position()
    hash_start = zobrist_hash(b)

    moves = [Move("g1", "f3"), Move("b8", "c6"), Move("f3", "g1"), Move("c6", "b8")]

    for m in moves
        make_move!(b, m)
    end

    new_hash = zobrist_hash(b)
    @test hash_start == new_hash

    b_copy = deepcopy(b)

    m1 = Move("e2", "e4")
    make_move!(b, m1)
    hash_after_move = zobrist_hash(b)

    m1 = Move("e2", "e3")
    m2 = Move("e3", "e4")

    make_move!(b_copy, m1)
    b_copy.side_to_move = WHITE
    make_move!(b_copy, m2)
    hash_after_two_moves = zobrist_hash(b_copy)

    @test hash_after_move != hash_after_two_moves
end
