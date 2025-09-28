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

function piece_symbol(piece::Int)
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
function piece_from_symbol(c::AbstractChar,  side::Side)
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
Construct a Move from a long algebraic string like "e2e4" or "e7e8=Q", 
using the board to infer capture, en passant, and castling.
"""
function Move(board::Board, str::AbstractString)
    # Castling shortcuts
    if str in ["O-O", "o-o", "0-0"]
        return Move(4, 6; castling = 1)
    elseif str in ["O-O-O", "o-o-o", "0-0-0"]
        return Move(4, 2; castling = 2)
    end

    # Parse squares
    from = square_from_name(str[1:2])
    to = square_from_name(str[3:4])

    # Parse promotion from string if present
    promotion = 0
    if length(str) > 4 && str[5] == '='
        piece_char = uppercase(str[6])
        promotion = piece_from_symbol(piece_char, board.side_to_move)
    end

    # Infer capture from board
    captured_piece = 0
    for p in 1:12
        if testbit(board.bitboards[p], to)
            captured_piece = p
            break
        end
    end

    # Infer en passant
    is_ep = false
    moving_piece = 0
    for p in (board.side_to_move == WHITE ? (Piece.W_PAWN:Piece.W_KING) : (Piece.B_PAWN:Piece.B_KING))
        if testbit(board.bitboards[p], from)
            moving_piece = p
            break
        end
    end
    if moving_piece in (Piece.W_PAWN, Piece.B_PAWN) && to == board.en_passant
        is_ep = true
        captured_piece = board.side_to_move == WHITE ? Piece.B_PAWN : Piece.W_PAWN
    end

    # Infer castling
    castling_type = 0
    if moving_piece in (Piece.W_KING, Piece.B_KING) && abs(to - from) == 2
        castling_type = to > from ? 1 : 2
    end

    return Move(from, to; promotion = promotion, capture = captured_piece,
        castling = castling_type, en_passant = is_ep)
end
