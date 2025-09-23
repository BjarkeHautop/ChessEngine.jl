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
Check if the game is over (checkmate, stalemate, draw)
- `board`: Board struct
Returns: Symbol (:checkmate_white, :checkmate_black, :stalemate, :draw_threefold, :draw_fiftymove, :ongoing)
"""
function game_over(board::Board)
    legal = generate_legal_moves(board)
    if isempty(legal)
        if in_check(board, board.side_to_move)
            return (board.side_to_move == WHITE) ? :checkmate_white : :checkmate_black
        else
            return :stalemate
        end
    end

    if is_threefold_repetition(board)
        return :draw_threefold
    elseif is_fifty_move_rule(board)
        return :draw_fiftymove
    end

    return :ongoing
end
