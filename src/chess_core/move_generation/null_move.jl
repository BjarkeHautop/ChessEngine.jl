"""
Apply a null move (pass) to the board, modifying it in place.
Used for null-move pruning.
"""
function make_null_move!(board::Board)
    push!(board.undo_stack,
        UndoInfo(
            0,                    # no captured piece
            board.en_passant,
            board.castling_rights,
            board.halfmove_clock,
            0,                    # no piece moved
            0,                    # no promotion
            false,                # not en passant
            board.eval_score,     # current eval
            board.game_phase_value # current game phase
        )
    )

    # Null move clears en passant
    board.en_passant = -1

    # Increment halfmove clock
    board.halfmove_clock += 1

    # Flip side
    board.side_to_move = board.side_to_move == WHITE ? BLACK : WHITE

    # Save new hash
    push!(board.position_history, zobrist_hash(board))

    return board
end

"""
Undo a null move, restoring the previous board state.
"""
function unmake_null_move!(board::Board)
    info = pop!(board.undo_stack)

    board.en_passant = info.en_passant
    board.castling_rights = info.castling_rights
    board.halfmove_clock = info.halfmove_clock
    board.eval_score = info.prev_eval_score
    board.game_phase_value = info.prev_game_phase_value

    # Flip side back
    board.side_to_move = board.side_to_move == WHITE ? BLACK : WHITE

    # Remove hash from history
    pop!(board.position_history)

    return board
end
