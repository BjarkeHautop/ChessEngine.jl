#########################
# Move helpers          #
#########################

"""
Check if a square index is on the board
"""
on_board(sq) = 0 <= sq <= 63

"""
Return file (1..8) and rank (1..8) for a square index
"""
file_rank(sq) = (sq % 8 + 1, sq ÷ 8 + 1)

"""
Get the square index of the king for the given side
- `board`: Board struct
- `side`: Side (WHITE or BLACK)
Returns: Int (square index 0..63)
"""
function king_square(board::Board, side::Side)
    bb = (side == WHITE) ? board.bitboards[Piece.W_KING] : board.bitboards[Piece.B_KING]
    for sq in 0:63
        if testbit(bb, sq)
            return sq
        end
    end
    return -1  # shouldn't happen
end

"""
Return the piece type at a given square (0..63) using bitboards.
"""
function piece_at(board::Board, sq)
    mask = UInt64(1) << sq
    for (p, bb) in enumerate(board.bitboards)
        if bb & mask != 0
            return p
        end
    end
    return 0
end

"""
Check if a square is attacked by the given side.
- `board`: Board struct
- `sq`: Int (square index 0..63)
- `attacker`: Side (WHITE or BLACK)
Returns: Bool
"""
function square_attacked(board::Board, sq, attacker::Side)::Bool
    ########################
    # 1) Pawn attacks
    ########################
    if attacker == WHITE
        pawn_attacks = [-9, -7]   # white pawns attack up-left / up-right
        pawns = board.bitboards[Piece.W_PAWN]
    else
        pawn_attacks = [7, 9]     # black pawns attack down-left / down-right
        pawns = board.bitboards[Piece.B_PAWN]
    end
    for d in pawn_attacks
        from = sq + d
        if on_board(from) && testbit(pawns, from)
            return true
        end
    end

    ########################
    # 2) Knight attacks
    ########################
    knight_deltas = [-17, -15, -10, -6, 6, 10, 15, 17]
    knights = (attacker == WHITE) ? board.bitboards[Piece.W_KNIGHT] :
              board.bitboards[Piece.B_KNIGHT]
    for d in knight_deltas
        from = sq + d
        if on_board(from)
            f1, r1 = file_rank(sq)
            f2, r2 = file_rank(from)
            if abs(f1 - f2) <= 2 && abs(r1 - r2) <= 2 && testbit(knights, from)
                return true
            end
        end
    end

    ########################
    # 3) Sliding pieces
    ########################
    occ = zero(UInt64)
    for p in ALL_PIECES
        occ |= board.bitboards[p]
    end

    function attacked_by_sliders(directions, bb_piece)
        for d in directions
            pos = sq
            prev_f, prev_r = file_rank(pos)
            while true
                pos += d
                if !on_board(pos)
                    break
                end
                f, r = file_rank(pos)
                if abs(f - prev_f) > 1 || abs(r - prev_r) > 1
                    break
                end
                prev_f, prev_r = f, r

                if testbit(occ, pos)
                    if testbit(bb_piece, pos)
                        return true   # correct slider found
                    else
                        break        # blocked by wrong piece
                    end
                end
            end
        end
        return false
    end

    # Bishops + queens (diagonals)
    if attacked_by_sliders(
        [-9, -7, 7, 9],
        if (attacker == WHITE)
            (board.bitboards[Piece.W_BISHOP] | board.bitboards[Piece.W_QUEEN])
        else
            (board.bitboards[Piece.B_BISHOP] | board.bitboards[Piece.B_QUEEN])
        end
    )
        return true
    end

    # Rooks + queens (orthogonals)
    if attacked_by_sliders(
        [-8, -1, 1, 8],
        if (attacker == WHITE)
            (board.bitboards[Piece.W_ROOK] | board.bitboards[Piece.W_QUEEN])
        else
            (board.bitboards[Piece.B_ROOK] | board.bitboards[Piece.B_QUEEN])
        end
    )
        return true
    end

    ########################
    # 4) King attacks
    ########################
    king_deltas = [-9, -8, -7, -1, 1, 7, 8, 9]
    kings = (attacker == WHITE) ? board.bitboards[Piece.W_KING] :
            board.bitboards[Piece.B_KING]
    for d in king_deltas
        from = sq + d
        if on_board(from) && testbit(kings, from)
            return true
        end
    end

    return false
end

"""
Check if the king of the given side is in check
- `board`: Board struct
- `side`: Side (WHITE or BLACK)
Returns: Bool
"""
function in_check(board::Board, side::Side)::Bool
    king_sq = king_square(board, side)
    attacker = opposite(side)
    return square_attacked(board, king_sq, attacker)
end

function generate_captures(board::Board)
    moves = generate_legal_moves(board)
    capture_moves = Move[]
    for m in moves
        if m.capture != 0
            push!(capture_moves, m)
        end
    end

    return capture_moves
end

function generate_captures!(board::Board, moves::Vector{Move})
    # Clear previous content
    empty!(moves)

    # Temporary vector to hold all legal moves
    temp = Vector{Move}(undef, 0)
    generate_legal_moves!(board, temp)

    # Filter in-place
    for m in temp
        if m.capture != 0
            push!(moves, m)
        end
    end

    return moves
end

# helper to find which enemy piece occupies a square
function find_capture_piece(board::Board, sq, start_piece, end_piece)
    for p in start_piece:end_piece
        if (board.bitboards[p] & (UInt64(1) << sq)) != 0
            return p
        end
    end
    return 0
end
