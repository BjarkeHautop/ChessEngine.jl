# Internal helper for king moves
# `push_fn` is a function used to append a move
function _king_moves_internal(board::Board, push_fn)
    if board.side_to_move == WHITE
        kings = board.bitboards[W_KING]
        friendly_pieces = W_PAWN:W_KING
        enemy_pieces = B_PAWN:B_KING
        rights = board.castling_rights
        king_sq = 4   # e1
    else
        kings = board.bitboards[B_KING]
        friendly_pieces = B_PAWN:B_KING
        enemy_pieces = W_PAWN:W_KING
        rights = board.castling_rights
        king_sq = 60  # e8
    end

    # Build bitboard of all friendly pieces
    occupied_friendly = zero(UInt64)
    for p in friendly_pieces
        occupied_friendly |= board.bitboards[p]
    end

    # King move offsets (one square in any direction)
    deltas = [-9, -8, -7, -1, 1, 7, 8, 9]

    for sq in 0:63
        if !testbit(kings, sq)
            continue
        end

        f, r = file_rank(sq)

        for d in deltas
            to_sq = sq + d
            if !on_board(to_sq)
                continue
            end

            tf, tr = file_rank(to_sq)
            if abs(tf - f) <= 1 && abs(tr - r) <= 1
                if !testbit(occupied_friendly, to_sq)
                    # Check for capture
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

        # Castling (pseudo-legal)
        if board.side_to_move == WHITE
            if testbit(kings, 4)
                # White kingside (K)
                if (rights & 0b0001) != 0 &&
                   !any(
                    testbit(board.bitboards[p], 5) || testbit(board.bitboards[p], 6)
                for p in ALL_PIECES
                )
                    push_fn(4, 6; castling = 1)
                end
                # White queenside (Q)
                if (rights & 0b0010) != 0 &&
                   !any(
                    testbit(board.bitboards[p], 1) ||
                    testbit(board.bitboards[p], 2) ||
                    testbit(board.bitboards[p], 3)
                for p in ALL_PIECES
                )
                    push_fn(4, 2; castling = 2)
                end
            end
        else
            if testbit(kings, 60)
                # Black kingside (k)
                if (rights & 0b0100) != 0 &&
                   !any(
                    testbit(board.bitboards[p], 61) || testbit(board.bitboards[p], 62)
                for p in ALL_PIECES
                )
                    push_fn(60, 62; castling = 1)
                end
                # Black queenside (q)
                if (rights & 0b1000) != 0 &&
                   !any(
                    testbit(board.bitboards[p], 57) ||
                    testbit(board.bitboards[p], 58) ||
                    testbit(board.bitboards[p], 59)
                for p in ALL_PIECES
                )
                    push_fn(60, 58; castling = 2)
                end
            end
        end
    end
end

# Return a vector
function generate_king_moves(board::Board)
    moves = Move[]
    _king_moves_internal(board, (from,to; kwargs...) -> push!(moves, Move(from,to; kwargs...)))
    return moves
end

# Fill an existing vector
function generate_king_moves!(board::Board, moves::Vector{Move})
    len_before = length(moves)
    _king_moves_internal(board, (from,to; kwargs...) -> push!(moves, Move(from,to; kwargs...)))
    return length(moves) - len_before
end
