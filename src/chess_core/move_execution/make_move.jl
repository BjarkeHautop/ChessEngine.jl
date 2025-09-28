"""
    make_move!(board, m)
Apply move `m` to board, modifying it in place.
- `board`: Board struct
- `m`: Move
"""
function make_move!(board::Board, m::Move)
    # --- Identify moving piece ---
    piece_type = 0
    if board.side_to_move == WHITE
        for p in Piece.W_PAWN:Piece.W_KING
            if testbit(board.bitboards[p], m.from)
                piece_type = p
                break
            end
        end
    else
        for p in Piece.B_PAWN:Piece.B_KING
            if testbit(board.bitboards[p], m.from)
                piece_type = p
                break
            end
        end
    end
    piece_type == 0 && error("No piece found on from-square $(m.from)")

    # --- Detect en passant capture ---
    is_ep = false
    if piece_type in (Piece.W_PAWN, Piece.B_PAWN) && m.to == board.en_passant
        is_ep = true
    end

    # --- Save UndoInfo before modifying ---
    push!(
        board.undo_stack,
        UndoInfo(
            m.capture,
            board.en_passant,
            board.castling_rights,
            board.halfmove_clock,
            piece_type,
            m.promotion,
            is_ep,
            board.eval_score,
            board.game_phase_value
        )
    )

    # --- Remove piece from origin square ---
    board.bitboards[piece_type] = clearbit(board.bitboards[piece_type], m.from)

    # --- Update eval: piece moved off origin ---
    board.eval_score -= piece_square_value(piece_type, m.from, game_phase(board))

    # --- Captures ---
    if m.capture != 0 && !is_ep
        board.bitboards[m.capture] = clearbit(board.bitboards[m.capture], m.to)
        board.eval_score -= piece_square_value(m.capture, m.to, game_phase(board))
        board.game_phase_value -= phase_weight(m.capture)
    elseif is_ep
        if board.side_to_move == WHITE
            captured_sq = m.to - 8
            board.bitboards[Piece.B_PAWN] = clearbit(board.bitboards[Piece.B_PAWN], captured_sq)
            board.eval_score -= piece_square_value(Piece.B_PAWN, captured_sq, game_phase(board))
            board.game_phase_value -= phase_weight(Piece.B_PAWN)
        else
            captured_sq = m.to + 8
            board.bitboards[Piece.W_PAWN] = clearbit(board.bitboards[Piece.W_PAWN], captured_sq)
            board.eval_score -= piece_square_value(Piece.W_PAWN, captured_sq, game_phase(board))
            board.game_phase_value -= phase_weight(Piece.W_PAWN)
        end
    end

    # --- Promotions / normal move ---
    if m.promotion != 0
        board.bitboards[m.promotion] = setbit(board.bitboards[m.promotion], m.to)
        board.eval_score += piece_square_value(m.promotion, m.to, game_phase(board))
        board.game_phase_value += phase_weight(m.promotion)
        board.game_phase_value -= phase_weight(piece_type)  # pawn removed
    else
        board.bitboards[piece_type] = setbit(board.bitboards[piece_type], m.to)
        board.eval_score += piece_square_value(piece_type, m.to, game_phase(board))
    end

    # --- Castling rook moves ---
    if piece_type == Piece.W_KING && m.from == 4 && abs(m.to - m.from) == 2
        if m.to == 6      # short castle (e1 → g1)
            board.bitboards[Piece.W_ROOK] = clearbit(board.bitboards[Piece.W_ROOK], 7)
            board.bitboards[Piece.W_ROOK] = setbit(board.bitboards[Piece.W_ROOK], 5)
            board.eval_score -= piece_square_value(Piece.W_ROOK, 7, game_phase(board))
            board.eval_score += piece_square_value(Piece.W_ROOK, 5, game_phase(board))
        elseif m.to == 2  # long castle (e1 → c1)
            board.bitboards[Piece.W_ROOK] = clearbit(board.bitboards[Piece.W_ROOK], 0)
            board.bitboards[Piece.W_ROOK] = setbit(board.bitboards[Piece.W_ROOK], 3)
            board.eval_score -= piece_square_value(Piece.W_ROOK, 0, game_phase(board))
            board.eval_score += piece_square_value(Piece.W_ROOK, 3, game_phase(board))
        end
    elseif piece_type == Piece.B_KING && m.from == 60 && abs(m.to - m.from) == 2
        if m.to == 62     # short castle (e8 → g8)
            board.bitboards[Piece.B_ROOK] = clearbit(board.bitboards[Piece.B_ROOK], 63)
            board.bitboards[Piece.B_ROOK] = setbit(board.bitboards[Piece.B_ROOK], 61)
            board.eval_score -= piece_square_value(Piece.B_ROOK, 63, game_phase(board))
            board.eval_score += piece_square_value(Piece.B_ROOK, 61, game_phase(board))
        elseif m.to == 58 # long castle (e8 → c8)
            board.bitboards[Piece.B_ROOK] = clearbit(board.bitboards[Piece.B_ROOK], 56)
            board.bitboards[Piece.B_ROOK] = setbit(board.bitboards[Piece.B_ROOK], 59)
            board.eval_score -= piece_square_value(Piece.B_ROOK, 56, game_phase(board))
            board.eval_score += piece_square_value(Piece.B_ROOK, 59, game_phase(board))
        end
    end

    # --- Update en passant target square ---
    board.en_passant = -1
    if piece_type == Piece.W_PAWN && (m.to - m.from) == 16
        board.en_passant = m.from + 8
    elseif piece_type == Piece.B_PAWN && (m.from - m.to) == 16
        board.en_passant = m.from - 8
    end

    # --- Update castling rights ---

    # If a king moved, clear both its castling bits
    if piece_type == Piece.W_KING
        board.castling_rights &= 0x0c   # clear 0x01 and 0x02 -> keep only 0x0c (1100)
    elseif piece_type == Piece.B_KING
        board.castling_rights &= 0x03   # clear 0x04 and 0x08 -> keep only 0x03 (0011)
    end

    # If a rook moved FROM its original square, clear that side's right.
    if piece_type == Piece.W_ROOK
        if m.from == 0                   # a1
            board.castling_rights &= 0x0d   # clear White Q (0x02) -> 0x0f & ~0x02 = 0x0d
        elseif m.from == 7               # h1
            board.castling_rights &= 0x0e   # clear White K (0x01) -> 0x0f & ~0x01 = 0x0e
        end
    end

    if piece_type == Piece.B_ROOK
        if m.from == 56                  # a8
            board.castling_rights &= 0x07   # clear Black q (0x08) -> 0x0f & ~0x08 = 0x07
        elseif m.from == 63              # h8
            board.castling_rights &= 0x0b   # clear Black k (0x04) -> 0x0f & ~0x04 = 0x0b
        end
    end

    # If a rook was captured ON its original square, clear that side's right.
    if m.capture == Piece.W_ROOK
        if m.to == 0
            board.castling_rights &= 0x0d   # clear White Q
        elseif m.to == 7
            board.castling_rights &= 0x0e   # clear White K
        end
    elseif m.capture == Piece.B_ROOK
        if m.to == 56
            board.castling_rights &= 0x07   # clear Black q
        elseif m.to == 63
            board.castling_rights &= 0x0b   # clear Black k
        end
    end

    # --- Halfmove clock (50-move rule) ---
    if piece_type in (Piece.W_PAWN, Piece.B_PAWN) || m.capture != 0 || m.promotion != 0
        board.halfmove_clock = 0
    else
        board.halfmove_clock += 1
    end

    # --- Save history & flip side ---
    push!(board.position_history, zobrist_hash(board))
    board.side_to_move = (board.side_to_move == WHITE ? BLACK : WHITE)
end

"""
    make_move(board, m) -> Board

Return a new board with move `m` applied, leaving the original board unchanged.
- `board`: Board struct
- `m`: Move
"""
function make_move(board::Board, m::Move)
    new_board = deepcopy(board)
    make_move!(new_board, m)
    return new_board
end
