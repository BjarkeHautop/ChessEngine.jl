"""
Generate pseudo-legal sliding piece moves (bishop, rook, queen)
- `board`: Board struct
- `bb_piece`: bitboard of the sliding piece type
- `directions`: vector of direction offsets (e.g. [-9, -7, 7, 9] for bishop)
Returns: Vector of Move
"""
function generate_sliding_moves(board::Board, bb_piece::UInt64, directions::Vector{Int})
    moves = Move[]

    # Friendly and enemy piece ranges
    if board.side_to_move == WHITE
        friendly_pieces = W_PAWN:W_KING
        enemy_pieces = B_PAWN:B_KING
    else
        friendly_pieces = B_PAWN:B_KING
        enemy_pieces = W_PAWN:W_KING
    end

    # Bitboard of all friendly pieces
    occupied_friendly = 0
    for p in friendly_pieces
        occupied_friendly |= board.bitboards[p]
    end

    for sq in 0:63
        if !testbit(bb_piece, sq)
            continue
        end
        f, r = file_rank(sq)

        for d in directions
            to_sq = sq
            prev_f, prev_r = f, r  # track previous square

            while true
                to_sq += d
                if !on_board(to_sq)
                    break
                end

                tf, tr = file_rank(to_sq)

                # Stop if piece would wrap around the board
                if abs(tf - prev_f) > 1 || abs(tr - prev_r) > 1
                    break
                end

                prev_f, prev_r = tf, tr

                # Stop if square is blocked by friendly piece
                if testbit(occupied_friendly, to_sq)
                    break
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

                # Stop sliding if captured
                if capture != 0
                    break
                end
            end
        end
    end

    return moves
end

"""
Generate pseudo-legal bishop moves for the given side
- `board`: Board struct
Returns: Vector of Move
"""
function generate_bishop_moves(board::Board)
    if board.side_to_move == WHITE
        bb = board.bitboards[W_BISHOP]
    else
        bb = board.bitboards[B_BISHOP]
    end
    directions = [-9, -7, 7, 9]  # diagonals
    return generate_sliding_moves(board, bb, directions)
end

"""
Generate pseudo-legal rook moves for the given side
- `board`: Board struct
Returns: Vector of Move
"""
function generate_rook_moves(board::Board)
    if board.side_to_move == WHITE
        bb = board.bitboards[W_ROOK]
    else
        bb = board.bitboards[B_ROOK]
    end
    directions = [-8, -1, 1, 8]  # orthogonal
    return generate_sliding_moves(board, bb, directions)
end

"""
Generate pseudo-legal queen moves for the given side
- `board`: Board struct
Returns: Vector of Move
"""
function generate_queen_moves(board::Board)
    if board.side_to_move == WHITE
        bb = board.bitboards[W_QUEEN]
    else
        bb = board.bitboards[B_QUEEN]
    end
    directions = [-9, -8, -7, -1, 1, 7, 8, 9]  # all directions
    return generate_sliding_moves(board, bb, directions)
end
