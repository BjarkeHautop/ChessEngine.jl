using ChessEngine
using Test

@testset "flip_index tests" begin
    # Corners
    @test ChessEngine.flip_index(1) == 57   # a1 → a8
    @test ChessEngine.flip_index(8) == 64   # h1 → h8
    @test ChessEngine.flip_index(57) == 1   # a8 → a1
    @test ChessEngine.flip_index(64) == 8   # h8 → h1

    # Middle squares
    @test ChessEngine.flip_index(9) == 49   # a2 → a7
    @test ChessEngine.flip_index(28) == 36  # d4 → d5
    @test ChessEngine.flip_index(36) == 28  # d5 → d4

    # Double flip should return original
    @test ChessEngine.flip_index(ChessEngine.flip_index(5)) == 5
end

@testset "piece_square_value tests" begin
    square = 1
    idx = ChessEngine.psqt_index(square)

    # Pawns
    @test ChessEngine.piece_square_value(W_PAWN, square, 1.0) ==
          ChessEngine.PAWN_TABLE_W[idx]
    @test ChessEngine.piece_square_value(B_PAWN, square, 1.0) ==
          -ChessEngine.PAWN_TABLE_B[idx]

    # Knights
    @test ChessEngine.piece_square_value(W_KNIGHT, square, 1.0) ==
          ChessEngine.KNIGHT_TABLE_W[idx]
    @test ChessEngine.piece_square_value(B_KNIGHT, square, 1.0) ==
          -ChessEngine.KNIGHT_TABLE_B[idx]

    # Bishops
    @test ChessEngine.piece_square_value(W_BISHOP, square, 1.0) ==
          ChessEngine.BISHOP_TABLE_W[idx]
    @test ChessEngine.piece_square_value(B_BISHOP, square, 1.0) ==
          -ChessEngine.BISHOP_TABLE_B[idx]

    # Rooks
    @test ChessEngine.piece_square_value(W_ROOK, square, 1.0) ==
          ChessEngine.ROOK_TABLE_W[idx]
    @test ChessEngine.piece_square_value(B_ROOK, square, 1.0) ==
          -ChessEngine.ROOK_TABLE_B[idx]

    # Queens
    @test ChessEngine.piece_square_value(W_QUEEN, square, 1.0) ==
          ChessEngine.QUEEN_TABLE_W[idx]
    @test ChessEngine.piece_square_value(B_QUEEN, square, 1.0) ==
          -ChessEngine.QUEEN_TABLE_B[idx]

    # Kings
    @test ChessEngine.piece_square_value(W_KING, square, 1.0) ==
          ChessEngine.KING_TABLE_W[idx]
    @test ChessEngine.piece_square_value(W_KING, square, 0.0) ==
          ChessEngine.KING_TABLE_END_W[idx]
    @test ChessEngine.piece_square_value(B_KING, square, 1.0) ==
          -ChessEngine.KING_TABLE_B[idx]
    @test ChessEngine.piece_square_value(B_KING, square, 0.0) ==
          -ChessEngine.KING_TABLE_END_B[idx]

    # Interpolation check (mid-phase)
    phase = 0.5
    expected_white = round(Int, 0.5 * ChessEngine.KING_TABLE_W[idx] +
                                0.5 * ChessEngine.KING_TABLE_END_W[idx])
    expected_black = round(
        Int, -(0.5 * ChessEngine.KING_TABLE_B[idx] +
               0.5 * ChessEngine.KING_TABLE_END_B[idx]))
    @test ChessEngine.piece_square_value(W_KING, square, phase) == expected_white
    @test ChessEngine.piece_square_value(B_KING, square, phase) == expected_black

    # Invalid piece should throw
    @test_throws ErrorException ChessEngine.piece_square_value(999, square, 1.0)
end
