# Internal shared logic for filtering pseudo-legal moves
function _filter_legal_moves!(board::Board, pseudo::Vector{Move}, start::Int,
        stop::Int, moves::Vector{Move}, n_moves::Int)
    side = board.side_to_move
    opp = opposite(side)
    @inbounds for i in start:stop
        m = pseudo[i]

        # Castling legality check
        if m.castling != 0
            if in_check(board, side)
                continue
            end

            # Castling path squares
            path = if side == WHITE
                m.castling == 1 ? (5, 6) : (3, 2)
            else
                m.castling == 1 ? (61, 62) : (59, 58)
            end

            illegal = false
            for sq in path
                if square_attacked(board, sq, opp)
                    illegal = true
                    break
                end
            end
            if illegal
                continue
            end
        end

        # Make move inplace and check legality
        make_move!(board, m)
        if in_check(board, side)
            undo_move!(board, m)
            continue
        end
        undo_move!(board, m)

        # Write move directly into preallocated array
        n_moves += 1
        moves[n_moves] = m
    end

    return n_moves
end

# Public API
function generate_legal_moves!(board::Board, moves::Vector{Move}, pseudo::Vector{Move})
    pseudo_len = 1
    pseudo_len = generate_pawn_moves!(board, pseudo, pseudo_len)
    pseudo_len = generate_knight_moves!(board, pseudo, pseudo_len)
    pseudo_len = generate_bishop_moves!(board, pseudo, pseudo_len)
    pseudo_len = generate_rook_moves!(board, pseudo, pseudo_len)
    pseudo_len = generate_queen_moves!(board, pseudo, pseudo_len)
    pseudo_len = generate_king_moves!(board, pseudo, pseudo_len)

    n_moves = 0
    # pseudo_len is one past the end
    n_moves = _filter_legal_moves!(board, pseudo, 1, pseudo_len-1, moves, n_moves)
    return n_moves
end

function generate_legal_moves(board::Board)
    moves = Vector{Move}(undef, MAX_MOVES)  # Preallocate maximum possible moves
    pseudo = Vector{Move}(undef, MAX_MOVES) # Preallocate maximum possible moves
    n_moves = generate_legal_moves!(board, moves, pseudo)
    return moves[1:n_moves]  # Return only the filled portion
end
