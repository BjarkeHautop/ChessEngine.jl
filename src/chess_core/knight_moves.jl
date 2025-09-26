# Internal helper for knight moves
function _generate_knight_moves_internal(board::Board, push_fn)
    knights, friendly_pieces,
    enemy_pieces = board.side_to_move == WHITE ?
                   (board.bitboards[W_KNIGHT], W_PAWN:W_KING, B_PAWN:B_KING) :
                   (board.bitboards[B_KNIGHT], B_PAWN:B_KING, W_PAWN:W_KING)

    # build bitboard of all friendly pieces
    occupied_friendly = zero(UInt64)
    for p in friendly_pieces
        occupied_friendly |= board.bitboards[p]
    end

    # Knight move offsets
    deltas = [-17, -15, -10, -6, 6, 10, 15, 17]

    for sq in 0:63
        if !testbit(knights, sq)
            continue
        end

        f, r = file_rank(sq)
        for d in deltas
            to_sq = sq + d
            if !on_board(to_sq)
                continue
            end

            tf, tr = file_rank(to_sq)
            df = abs(tf - f)
            dr = abs(tr - r)

            # Only valid L-shaped moves
            if (df == 2 && dr == 1) || (df == 1 && dr == 2)
                if !testbit(occupied_friendly, to_sq)
                    # capture check
                    capture = 0
                    for p in enemy_pieces
                        if testbit(board.bitboards[p], to_sq)
                            capture = p
                            break
                        end
                    end
                    push_fn(sq, to_sq; capture = capture)
                end
            end
        end
    end
end

# Returns a vector of moves
function generate_knight_moves(board::Board)
    moves = Move[]
    _generate_knight_moves_internal(board, (
        sq, to_sq; kwargs...) -> push!(moves, Move(sq, to_sq; kwargs...)))
    return moves
end

# In-place version
function generate_knight_moves!(board::Board, moves::Vector{Move})
    len_before = length(moves)
    _generate_knight_moves_internal(board, (
        sq, to_sq; kwargs...) -> push!(moves, Move(sq, to_sq; kwargs...)))
    return length(moves) - len_before
end
