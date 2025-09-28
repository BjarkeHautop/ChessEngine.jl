"""
Check for threefold repetition
- `board`: Board struct
Returns: Bool
"""
function is_threefold_repetition(board::Board)
    if isempty(board.position_history)
        return false
    end
    last_key = board.position_history[end]
    n = count(k -> k == last_key, board.position_history)
    return n >= 3
end

"""
Check for fifty-move rule
- `board`: Board struct
Returns: Bool
"""
function is_fifty_move_rule(board::Board)
    return board.halfmove_clock >= 100  # 100 plies = 50 full moves
end

"""
Check for insufficient material to mate
- `board`: Board struct
Returns: Bool
"""
function is_insufficient_material(board::Board)
    # Count pieces using bitboards
    function count_bits(bb::UInt64)
        return count_ones(bb)
    end

    # Quick check: any pawns, rooks, or queens → material is sufficient
    if count_bits(board.bitboards[W_PAWN]) > 0 || count_bits(board.bitboards[B_PAWN]) > 0 ||
       count_bits(board.bitboards[W_ROOK]) > 0 || count_bits(board.bitboards[B_ROOK]) > 0 ||
       count_bits(board.bitboards[W_QUEEN]) > 0 || count_bits(board.bitboards[B_QUEEN]) > 0
        return false
    end

    # Count minor pieces
    w_minors = count_bits(board.bitboards[W_BISHOP]) + count_bits(board.bitboards[W_KNIGHT])
    b_minors = count_bits(board.bitboards[B_BISHOP]) + count_bits(board.bitboards[B_KNIGHT])

    # Only kings
    if w_minors == 0 && b_minors == 0
        return true
    end

    # King + single minor vs king
    if (w_minors == 1 && b_minors == 0) || (w_minors == 0 && b_minors == 1)
        return true
    end

    # King + bishop vs king + bishop (same color squares)
    if w_minors == 1 && b_minors == 1
        # Get bishop squares
        wb_sq = trailing_zeros(board.bitboards[W_BISHOP])
        bb_sq = trailing_zeros(board.bitboards[B_BISHOP])
        # Check square color: light=0, dark=1
        if (wb_sq % 8 + wb_sq ÷ 8) % 2 == (bb_sq % 8 + bb_sq ÷ 8) % 2
            return true
        end
    end

    return false
end

"""
Check if the game is over (checkmate, stalemate, draw)
- `board`: Board struct
Returns: Symbol (:checkmate_white, :checkmate_black, :stalemate, :draw_threefold, :draw_fiftymove, 
:draw_insufficient_material, :ongoing)
"""
function game_over(board::Board)
    legal = generate_legal_moves(board)
    if isempty(legal)
        if in_check(board, board.side_to_move)
            return (board.side_to_move == WHITE) ? :checkmate_black : :checkmate_white
        else
            return :stalemate
        end
    end

    if is_insufficient_material(board)
        return :draw_insufficient_material

    elseif is_threefold_repetition(board)
        return :draw_threefold
    elseif is_fifty_move_rule(board)
        return :draw_fiftymove
    end

    return :ongoing
end
