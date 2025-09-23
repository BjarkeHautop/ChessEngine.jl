using ChessEngine
using Test

@testset "Pawn move generation" begin
    b = start_position()

    # Generate white pawn moves from starting position
    white_moves = generate_pawn_moves(b)

    # There should be 16 moves: each of the 8 pawns can move 1 or 2 squares
    @test length(white_moves) == 16

    # Check a few specific moves
    expected_moves = [
        Move("a2", "a3"), Move("a2", "a4"), Move("e2", "e3"), Move("e2", "e4")
    ]

    for em in expected_moves
        @test em in white_moves
    end

    # Now test black pawn moves after switching side to move
    b.side_to_move = BLACK
    black_moves = generate_pawn_moves(b)

    # There should also be 16 moves for black pawns
    @test length(black_moves) == 16

    expected_black_moves = [
        Move(square_index(1, 7), square_index(1, 6)),  # a7 to a6
        Move(square_index(1, 7), square_index(1, 5)),  # a7 to a5
        Move(square_index(5, 7), square_index(5, 6)),  # e7 to e6
        Move(square_index(5, 7), square_index(5, 5))   # e7 to e5
    ]

    for em in expected_black_moves
        @test em in black_moves
    end

    # -----------------------------
    # Test en passant generation
    # -----------------------------
    # Example: white pawn on e5 can capture black pawn on d5 en passant
    b = start_position()
    make_move!(b, Move("e2", "e4"))
    make_move!(b, Move("a7", "a5"))

    make_move!(b, Move("e4", "e5"))
    # Black plays d7-d5
    make_move!(b, Move("d7", "d5"))
    # Now white pawn on e5 can capture d5 en passant
    white_moves = generate_pawn_moves(b)
    en_passant_move = Move("e5", "d6"; capture = 7, en_passant = true)

    @test en_passant_move in white_moves

    make_move!(b, en_passant_move)
    # Check that the black pawn on d5 is removed
    @test !testbit(b.bitboards[B_PAWN], square_index(4, 5))
    # Check that white pawn is now on d6
    @test testbit(b.bitboards[W_PAWN], square_index(4, 6))

    # -----------------------------
    # Test promotion generation
    # -----------------------------
    # Clear pieces to allow pawn promotion

    bitboards = Dict{Int, UInt64}()
    for p in W_PAWN:B_KING
        bitboards[p] = UInt64(0)
    end
    bitboards[W_KING] = setbit(UInt64(0), square_index(5, 1))
    bitboards[B_KING] = setbit(UInt64(0), square_index(5, 8))
    bitboards[W_PAWN] = setbit(UInt64(0), square_index(7, 7))
    bitboards[B_ROOK] = setbit(UInt64(0), square_index(8, 8))

    b = Board(bitboards, WHITE, 0x0, -1, 0, UInt64[], UndoInfo[], 0, 0)
    promotion_moves = generate_pawn_moves(b)
    expected_promotions = [
        Move("g7", "g8"; promotion = W_QUEEN),
        Move("g7", "g8"; promotion = W_ROOK),
        Move("g7", "g8"; promotion = W_BISHOP),
        Move("g7", "g8"; promotion = W_KNIGHT),
        Move("g7", "h8"; promotion = W_QUEEN, capture = B_ROOK)
    ]
    for em in expected_promotions
        @test em in promotion_moves
    end
end

@testset "Pawn move generation" begin
    b = start_position()
    make_move!(b, Move("a2", "a4"))
    make_move!(b, Move("h7", "h4"))

    pawn_moves = generate_pawn_moves(b)
    illegal_mv = Move("a4", "h4"; capture = B_PAWN)
    @test illegal_mv ∉ pawn_moves
end

@testset "generate_legal_moves for pawns" begin
    b = start_position()
    make_move!(b, Move("e2", "e5"))
    make_move!(b, Move("d7", "d5"))

    legal_moves = generate_legal_moves(b)
    en_passant_move = Move("e5", "d6"; capture = B_PAWN, en_passant = true)
    @test en_passant_move in legal_moves
end
