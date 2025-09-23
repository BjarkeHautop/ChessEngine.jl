"""
Generate pseudo-legal knight moves for the given side
- `board`: Board struct
Returns: Vector of Move
"""
function generate_knight_moves(board::Board)
    moves = Move[]

    if board.side_to_move == WHITE
        knights = board.bitboards[W_KNIGHT]
        enemy_pieces = B_PAWN:B_KING
        friendly_pieces = W_PAWN:W_KING
    else
        knights = board.bitboards[B_KNIGHT]
        enemy_pieces = W_PAWN:W_KING
        friendly_pieces = B_PAWN:B_KING
    end

    # Build bitboard of all friendly pieces
    occupied_friendly = 0
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

            # Only keep valid knight moves
            if (df == 2 && dr == 1) || (df == 1 && dr == 2)
                # Skip squares occupied by friendly pieces
                if testbit(occupied_friendly, to_sq)
                    continue
                end

                # Check for capture
                capture = 0
                for p in enemy_pieces
                    if testbit(board.bitboards[p], to_sq)
                        capture = p
                        break
                    end
                end

                push!(moves, Move(sq, to_sq; capture = capture))
            end
        end
    end

    return moves
end
