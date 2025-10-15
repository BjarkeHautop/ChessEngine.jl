const START_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

Board(; fen::String = START_FEN) = board_from_fen(fen)

function Game(; minutes = 3, increment = 2, fen::String = START_FEN)
    Game(Board(fen = fen),
        minutes * 60 * 1000,
        minutes * 60 * 1000,
        increment * 1000)
end

function Game(tc::AbstractString; fen::String = START_FEN)
    m, inc = split(tc, "+")
    Game(minutes = parse(Int, m), increment = parse(Int, inc), fen = fen)
end

function Base.show(io::IO, m::Move)
    # Print castling moves as "O-O" or "O-O-O"
    if m.castling == 1
        print(io, "O-O")    # kingside
        return
    elseif m.castling == 2
        print(io, "O-O-O")  # queenside
        return
    end

    # Normal move
    s = string(square_name(m.from), square_name(m.to))
    if m.promotion != 0
        s *= "=" * piece_symbol(m.promotion)
    end
    print(io, s)
end

function piece_symbol(piece)
    if piece == Piece.W_QUEEN || piece == Piece.B_QUEEN
        return "Q"
    elseif piece == Piece.W_ROOK || piece == Piece.B_ROOK
        return "R"
    elseif piece == Piece.W_BISHOP || piece == Piece.B_BISHOP
        return "B"
    elseif piece == Piece.W_KNIGHT || piece == Piece.B_KNIGHT
        return "N"
    else
        return ""
    end
end

"""
    piece_from_symbol(c::AbstractChar, side::Symbol)

Return the piece constant corresponding to promotion symbol `c` and the moving side (`:white` or `:black`).
"""
function piece_from_symbol(c::AbstractChar, side::Side)
    piece = nothing
    if c == 'Q'
        piece = side == :white ? Piece.W_QUEEN : Piece.B_QUEEN
    elseif c == 'R'
        piece = side == :white ? Piece.W_ROOK : Piece.B_ROOK
    elseif c == 'B'
        piece = side == :white ? Piece.W_BISHOP : Piece.B_BISHOP
    elseif c == 'N'
        piece = side == :white ? Piece.W_KNIGHT : Piece.B_KNIGHT
    else
        error("Invalid promotion piece: $c")
    end
    return piece
end

"""
    Move(board::Board, str::AbstractString)
Construct a Move from a long algebraic string like "e2e4" or "e7e8=Q", 
using the board to infer capture, en passant, and castling.
- `board`: current Board state
- `str`: move string in long algebraic notation

Captures are inferred based on the board state (so "e4d5" captures if d5 is occupied by opponent).
Castling can be specified with "O-O" (kingside) or "O-O-O" (queenside). 
Also accepts "o-o", "0-0", "o-o-o", "0-0-0".
"""
function Move(board::Board, str::AbstractString)
    # Castling shortcuts
    if str in ["O-O", "o-o", "0-0"]
        return Move(Int8(4), Int8(6); castling = Int8(1))
    elseif str in ["O-O-O", "o-o-o", "0-0-0"]
        return Move(Int8(4), Int8(2); castling = Int8(2))
    end

    # Parse squares
    from = square_from_name(str[1:2])
    to = square_from_name(str[3:4])

    # Parse promotion if present
    promotion = 0
    if length(str) > 4
        if str[5] == '='
            # old format e7e8=Q
            promotion_char = uppercase(str[6])
        else
            # UCI-style format e7e8q
            promotion_char = uppercase(str[5])
        end
        promotion = piece_from_symbol(promotion_char, board.side_to_move)
    end

    # Infer captured piece
    captured_piece = 0
    for p in 1:12
        captured_piece = testbit(board.bitboards[p], to) ? p : captured_piece
    end

    # Infer en passant
    moving_piece = 0
    for p in (board.side_to_move == WHITE ? (Piece.W_PAWN:Piece.W_KING) :
         (Piece.B_PAWN:Piece.B_KING))
        if testbit(board.bitboards[p], from)
            moving_piece = p
            break
        end
    end

    is_ep = moving_piece in (Piece.W_PAWN, Piece.B_PAWN) && to == board.en_passant
    if is_ep
        captured_piece = board.side_to_move == WHITE ? Piece.B_PAWN : Piece.W_PAWN
    end

    return Move(
        Int8(from),
        Int8(to);
        promotion = Int8(promotion),
        capture = Int8(captured_piece),
        castling = Int8(0),
        en_passant = is_ep
    )
end
