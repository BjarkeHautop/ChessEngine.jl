using OrbisChessEngine
using Test

@testset "flip_index tests" begin
    # Corners
    @test OrbisChessEngine.flip_index(1) == 57   # a1 → a8
    @test OrbisChessEngine.flip_index(8) == 64   # h1 → h8
    @test OrbisChessEngine.flip_index(57) == 1   # a8 → a1
    @test OrbisChessEngine.flip_index(64) == 8   # h8 → h1

    # Middle squares
    @test OrbisChessEngine.flip_index(9) == 49   # a2 → a7
    @test OrbisChessEngine.flip_index(28) == 36  # d4 → d5
    @test OrbisChessEngine.flip_index(36) == 28  # d5 → d4

    # Double flip should return original
    @test OrbisChessEngine.flip_index(OrbisChessEngine.flip_index(5)) == 5
end

@testset "piece_square_value tests" begin
    square = 1
    idx = OrbisChessEngine.psqt_index(square)

    # Pawns
    @test OrbisChessEngine.piece_square_value(Piece.W_PAWN, square, 1.0) ==
          OrbisChessEngine.PAWN_TABLE_W[idx]
    @test OrbisChessEngine.piece_square_value(Piece.B_PAWN, square, 1.0) ==
          -OrbisChessEngine.PAWN_TABLE_B[idx]

    # Knights
    @test OrbisChessEngine.piece_square_value(Piece.W_KNIGHT, square, 1.0) ==
          OrbisChessEngine.KNIGHT_TABLE_W[idx]
    @test OrbisChessEngine.piece_square_value(Piece.B_KNIGHT, square, 1.0) ==
          -OrbisChessEngine.KNIGHT_TABLE_B[idx]

    # Bishops
    @test OrbisChessEngine.piece_square_value(Piece.W_BISHOP, square, 1.0) ==
          OrbisChessEngine.BISHOP_TABLE_W[idx]
    @test OrbisChessEngine.piece_square_value(Piece.B_BISHOP, square, 1.0) ==
          -OrbisChessEngine.BISHOP_TABLE_B[idx]

    # Rooks
    @test OrbisChessEngine.piece_square_value(Piece.W_ROOK, square, 1.0) ==
          OrbisChessEngine.ROOK_TABLE_W[idx]
    @test OrbisChessEngine.piece_square_value(Piece.B_ROOK, square, 1.0) ==
          -OrbisChessEngine.ROOK_TABLE_B[idx]

    # Queens
    @test OrbisChessEngine.piece_square_value(Piece.W_QUEEN, square, 1.0) ==
          OrbisChessEngine.QUEEN_TABLE_W[idx]
    @test OrbisChessEngine.piece_square_value(Piece.B_QUEEN, square, 1.0) ==
          -OrbisChessEngine.QUEEN_TABLE_B[idx]

    # Kings
    @test OrbisChessEngine.piece_square_value(Piece.W_KING, square, 1.0) ==
          OrbisChessEngine.KING_TABLE_W[idx]
    @test OrbisChessEngine.piece_square_value(Piece.W_KING, square, 0.0) ==
          OrbisChessEngine.KING_TABLE_END_W[idx]
    @test OrbisChessEngine.piece_square_value(Piece.B_KING, square, 1.0) ==
          -OrbisChessEngine.KING_TABLE_B[idx]
    @test OrbisChessEngine.piece_square_value(Piece.B_KING, square, 0.0) ==
          -OrbisChessEngine.KING_TABLE_END_B[idx]

    # Interpolation check (mid-phase)
    phase = 0.5
    expected_white = round(
        Int, 0.5 * OrbisChessEngine.KING_TABLE_W[idx] +
             0.5 * OrbisChessEngine.KING_TABLE_END_W[idx])
    expected_black = round(
        Int, -(0.5 * OrbisChessEngine.KING_TABLE_B[idx] +
               0.5 * OrbisChessEngine.KING_TABLE_END_B[idx]))
    @test OrbisChessEngine.piece_square_value(Piece.W_KING, square, phase) == expected_white
    @test OrbisChessEngine.piece_square_value(Piece.B_KING, square, phase) == expected_black

    # Invalid piece should throw
    @test_throws ErrorException OrbisChessEngine.piece_square_value(999, square, 1.0)
end

@testset "flip_table tests" begin
    # Simple case: numbers 1–64
    tbl = collect(1:64)
    flipped = OrbisChessEngine.flip_table(tbl)

    # Test 1: Check that flipping twice restores the original
    @test OrbisChessEngine.flip_table(flipped) == tbl

    # Test 2: Check that each rank is flipped vertically
    for rank in 0:7
        orig_row = tbl[(rank * 8 + 1):(rank * 8 + 8)]
        flipped_row = flipped[((7 - rank) * 8 + 1):((7 - rank) * 8 + 8)]
        @test flipped_row == orig_row
    end

    # Test 3: Spot-check a few indices
    # top-left (a8) should move to bottom-left (a1)
    @test flipped[1] == tbl[57]
    # bottom-right (h1) should move to top-right (h8)
    @test flipped[64] == tbl[8]
    # center square (e4) = rank 3, file 4 -> should map to e5 = rank 4, file 4
    src = 3 * 8 + 4 + 1  # 29
    dst = (7 - 3) * 8 + 4 + 1  # 37
    @test flipped[dst] == tbl[src]
end
