# Internal helper for sliding moves
function _generate_sliding_moves_internal(board::Board, bb_piece::UInt64, directions::Vector{Int}, push_fn)
    friendly_pieces,
    enemy_pieces = board.side_to_move == WHITE ?
                   (W_PAWN:W_KING, B_PAWN:B_KING) :
                   (B_PAWN:B_KING, W_PAWN:W_KING)

    # Bitboard of all friendly pieces
    occupied_friendly = zero(UInt64)
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
            prev_f, prev_r = f, r

            while true
                to_sq += d
                if !on_board(to_sq)
                    break
                end

                tf, tr = file_rank(to_sq)
                if abs(tf - prev_f) > 1 || abs(tr - prev_r) > 1
                    break
                end
                prev_f, prev_r = tf, tr

                # Stop if blocked by friendly piece
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

                push_fn(sq, to_sq; capture = capture)

                # Stop sliding if captured
                if capture != 0
                    break
                end
            end
        end
    end
end

# Returns new vector
function generate_sliding_moves(board::Board, bb_piece::UInt64, directions::Vector{Int})
    moves = Move[]
    _generate_sliding_moves_internal(board, bb_piece, directions,
        (sq, to_sq; kwargs...) -> push!(moves, Move(sq, to_sq; kwargs...)))
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

# In-place version
function generate_sliding_moves!(board::Board, bb_piece::UInt64, directions::Vector{Int}, moves::Vector{Move})
    len_before = length(moves)
    _generate_sliding_moves_internal(board, bb_piece, directions,
        (sq, to_sq; kwargs...) -> push!(moves, Move(sq, to_sq; kwargs...)))
    return length(moves) - len_before
end

# In-place bishop moves
function generate_bishop_moves!(board::Board, moves::Vector{Move})
    bb = board.side_to_move == WHITE ? board.bitboards[W_BISHOP] : board.bitboards[B_BISHOP]
    directions = [-9, -7, 7, 9]  # diagonals
    return generate_sliding_moves!(board, bb, directions, moves)
end

# In-place rook moves
function generate_rook_moves!(board::Board, moves::Vector{Move})
    bb = board.side_to_move == WHITE ? board.bitboards[W_ROOK] : board.bitboards[B_ROOK]
    directions = [-8, -1, 1, 8]  # orthogonal
    return generate_sliding_moves!(board, bb, directions, moves)
end

# In-place queen moves
function generate_queen_moves!(board::Board, moves::Vector{Move})
    bb = board.side_to_move == WHITE ? board.bitboards[W_QUEEN] : board.bitboards[B_QUEEN]
    directions = [-9, -8, -7, -1, 1, 7, 8, 9]  # all directions
    return generate_sliding_moves!(board, bb, directions, moves)
end
