using ChessEngine
using Test

@testset "Unmake normal moves" begin
    # Normal move
    b = Board()
    original_board = deepcopy(b)
    original_hash = ChessEngine.zobrist_hash(b)
    m1 = Move("e2", "e4")
    make_move!(b, m1)
    undo_move!(b, m1)
    @test b == original_board
    @test ChessEngine.zobrist_hash(b) == original_hash
end

@testset "Unmake capture moves" begin
    # Capture
    b = Board()
    # Set up a simple capture
    make_move!(b, Move("e2", "e4"))
    make_move!(b, Move("d7", "d5"))
    m_capture = Move("e4", "d5"; capture = Piece.B_PAWN)
    original_board = deepcopy(b)

    original_hash = ChessEngine.zobrist_hash(b)
    make_move!(b, m_capture)
    undo_move!(b, m_capture)
    @test b == original_board
    @test ChessEngine.zobrist_hash(b) == original_hash
end

@testset "Unmake promotion moves" begin
    b = Board()
    moves = [
        Move("a2", "a4"),
        Move("b7", "b5"),
        Move("a4", "b5"; capture = Piece.B_PAWN),
        Move("h7", "h6"),
        Move("b5", "b6"),
        Move("h6", "h5"),
        Move("b6", "b7"),
        Move("b8", "c6")
    ]

    for m in moves
        make_move!(b, m)
    end
    original_board = deepcopy(b)
    original_hash = ChessEngine.zobrist_hash(b)
    m_promo = Move("b7", "b8"; promotion = Piece.W_QUEEN)
    make_move!(b, m_promo)
    undo_move!(b, m_promo)
    @test b == original_board
    @test ChessEngine.zobrist_hash(b) == original_hash
end

@testset "Unmake promotion and capture moves" begin
    b = Board()
    moves = [
        Move("a2", "a4"),
        Move("b7", "b5"),
        Move("a4", "b5"; capture = Piece.B_PAWN),
        Move("h7", "h6"),
        Move("b5", "b6"),
        Move("h6", "h5"),
        Move("b6", "b7"),
        Move("h5", "h4")
    ]

    for m in moves
        make_move!(b, m)
    end
    original_board = deepcopy(b)
    original_hash = ChessEngine.zobrist_hash(b)
    m_promo = Move("b7", "a8"; capture = Piece.B_ROOK, promotion = Piece.W_QUEEN)
    make_move!(b, m_promo)
    undo_move!(b, m_promo)
    @test b == original_board
    @test ChessEngine.zobrist_hash(b) == original_hash
end

@testset "Unmake castling" begin
    b = Board()
    # Clear squares between king and rook for kingside castling
    b.bitboards[Piece.W_KNIGHT] = ChessEngine.clearbit(
        b.bitboards[Piece.W_KNIGHT], ChessEngine.square_index(7, 1))
    b.bitboards[Piece.W_BISHOP] = ChessEngine.clearbit(
        b.bitboards[Piece.W_BISHOP], ChessEngine.square_index(6, 1))
    m_castle = Move("e1", "g1"; castling = 1)  # kingside castle
    original_board = deepcopy(b)
    original_hash = ChessEngine.zobrist_hash(b)
    make_move!(b, m_castle)
    undo_move!(b, m_castle)
    @test b == original_board
    @test ChessEngine.zobrist_hash(b) == original_hash
end

@testset "Unmake en passant" begin
    b = Board()
    # White pawn to e5
    make_move!(b, Move("e2", "e5"))
    make_move!(b, Move("d7", "d5"))
    m_ep = Move("e5", "d6"; capture = Piece.B_PAWN, en_passant = true)
    original_board = deepcopy(b)
    original_hash = ChessEngine.zobrist_hash(b)
    make_move!(b, m_ep)
    undo_move!(b, m_ep)
    @test b == original_board
    @test ChessEngine.zobrist_hash(b) == original_hash
end
