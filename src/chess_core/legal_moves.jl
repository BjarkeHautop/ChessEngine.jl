# Internal shared logic for filtering pseudo-legal moves
function _filter_legal_moves!(board::Board, pseudo::Vector{Move}, moves::Vector{Move}; inplace::Bool = false)
    empty!(moves)
    side = board.side_to_move
    opp = opposite(side)

    for m in pseudo
        # --------------------
        # Castling legality check
        # --------------------
        if m.castling != 0
            if in_check(board, side)
                continue
            end

            path = if side == WHITE
                m.castling == 1 ? (5, 6) : (3, 2)
            else
                m.castling == 1 ? (61, 62) : (59, 58)
            end

            if any(sq -> square_attacked(board, sq, opp), path)
                continue
            end
        end

        if inplace
            make_move!(board, m)
            if in_check(board, side)
                undo_move!(board, m)
                continue
            end
            undo_move!(board, m)
            push!(moves, m)
        else
            new_board = deepcopy(board)
            make_move!(new_board, m)
            if !in_check(new_board, side)
                push!(moves, m)
            end
        end
    end

    return moves
end

# Public API
function generate_legal_moves(board::Board)
    pseudo = vcat(
        generate_pawn_moves(board),
        generate_knight_moves(board),
        generate_bishop_moves(board),
        generate_rook_moves(board),
        generate_queen_moves(board),
        generate_king_moves(board)
    )
    _filter_legal_moves!(board, pseudo, Move[]; inplace = false)
end

function generate_legal_moves!(board::Board, moves::Vector{Move})
    pseudo = Move[]
    ChessEngine.generate_pawn_moves!(board, pseudo)
    ChessEngine.generate_knight_moves!(board, pseudo)
    ChessEngine.generate_bishop_moves!(board, pseudo)
    ChessEngine.generate_rook_moves!(board, pseudo)
    ChessEngine.generate_queen_moves!(board, pseudo)
    ChessEngine.generate_king_moves!(board, pseudo)
    _filter_legal_moves!(board, pseudo, moves; inplace = true)
end
