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
    if piece == W_QUEEN || piece == B_QUEEN
        return "Q"
    elseif piece == W_ROOK || piece == B_ROOK
        return "R"
    elseif piece == W_BISHOP || piece == B_BISHOP
        return "B"
    elseif piece == W_KNIGHT || piece == B_KNIGHT
        return "N"
    else
        return ""
    end
end

function piece_from_symbol(c::AbstractChar)
    if c == 'Q'
        ;
        return W_QUEEN  # you may want to make this color-agnostic
    elseif c == 'R'
        ;
        return W_ROOK
    elseif c == 'B'
        ;
        return W_BISHOP
    elseif c == 'N'
        ;
        return W_KNIGHT
    else
        error("Invalid promotion piece: $c")
    end
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
        promotion = piece_from_symbol(piece_char)
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
    for p in (board.side_to_move == WHITE ? (W_PAWN:W_KING) : (B_PAWN:B_KING))
        if testbit(board.bitboards[p], from)
            moving_piece = p
            break
        end
    end
    if moving_piece in (W_PAWN, B_PAWN) && to == board.en_passant
        is_ep = true
        captured_piece = board.side_to_move == WHITE ? B_PAWN : W_PAWN
    end

    # Infer castling
    castling_type = 0
    if moving_piece in (W_KING, B_KING) && abs(to - from) == 2
        castling_type = to > from ? 1 : 2
    end

    return Move(from, to; promotion = promotion, capture = captured_piece,
        castling = castling_type, en_passant = is_ep)
end
