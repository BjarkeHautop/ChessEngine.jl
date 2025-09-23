using ChessEngine
using Test

@testset "Board basics" begin
    b = start_position()

    # side to move should be white
    @test b.side_to_move == WHITE

    # castling rights should be 0xF at start (all available)
    @test b.castling_rights == 0xF

    # en passant should be unset (-1)
    @test b.en_passant == -1

    # white pawns bitboard should match second rank
    expected_white_pawns = 0x000000000000FF00
    @test b.bitboards[W_PAWN] == expected_white_pawns

    # black rooks on a8 and h8
    expected_black_rooks = 0x8100000000000000
    @test b.bitboards[B_ROOK] == expected_black_rooks

    # Move e2 to e4
    m_square_index = Move(square_index(5, 2), square_index(5, 4))
    m_chess_notation = Move("e2", "e4")
    @test m_square_index == m_chess_notation
end

@testset "Square indexing" begin
    # a1 → 0
    @test square_index(1, 1) == 0

    # h1 → 7
    @test square_index(8, 1) == 7

    # a8 → 56
    @test square_index(1, 8) == 56

    # h8 → 63
    @test square_index(8, 8) == 63
end

@testset "Bit operations" begin
    sq = square_index(5, 2)  # e2
    bb = UInt64(0)

    # set bit
    bb = setbit(bb, sq)
    @test testbit(bb, sq)

    # clear bit
    bb = clearbit(bb, sq)
    @test !testbit(bb, sq)
end

@testset "Phase value calculated correctly" begin
    b = start_position()
    @test b.game_phase_value == 24
    @test b.eval_score == 0

    make_move!(b, Move("e2", "e3"))
    make_move!(b, Move("d7", "d5"))
    make_move!(b, Move("f1", "c4"))
    make_move!(b, Move("d5", "c4"; capture = W_BISHOP))

    @test b.game_phase_value == 23
    @test b.eval_score < 0

    eval_score, game_phase_value = compute_eval_and_phase(b)
    @test game_phase_value == b.game_phase_value
    @test eval_score == b.eval_score

    make_move!(b, Move("d1", "c4"; capture = B_PAWN))
    unmake_move!(b, Move("d1", "c4"; capture = B_PAWN))
    @test game_phase_value == b.game_phase_value
    @test eval_score == b.eval_score
end
