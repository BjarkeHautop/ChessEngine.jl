"""
Generate all legal moves for the given side
- `board`: Board struct
Returns: Vector of Move
"""
function generate_legal_moves(board::Board)
    pseudo = vcat(
        generate_pawn_moves(board),
        generate_knight_moves(board),
        generate_bishop_moves(board),
        generate_rook_moves(board),
        generate_queen_moves(board),
        generate_king_moves(board)
    )

    legal = Move[]
    side_that_moved = board.side_to_move
    opponent = opposite(side_that_moved)

    for m in pseudo
        # --------------------
        # Castling legality check (do this on the original board)
        # --------------------
        if m.castling != 0
            # king must not be currently in check
            if in_check(board, side_that_moved)
                continue
            end

            path = if side_that_moved == WHITE
                if m.castling == 1
                    [square_index(6, 1), square_index(7, 1)]  # f1, g1
                else
                    [square_index(4, 1), square_index(3, 1)]  # d1, c1
                end
            else
                if m.castling == 1
                    [square_index(6, 8), square_index(7, 8)]  # f8, g8
                else
                    [square_index(4, 8), square_index(3, 8)]  # d8, c8
                end
            end

            # none of these squares may be attacked in the current position
            if any(sq -> square_attacked(board, sq, opponent), path)
                continue
            end
        end

        # now apply the move and check the resulting position as usual
        new_board = deepcopy(board)
        make_move!(new_board, m)

        if !in_check(new_board, side_that_moved)
            push!(legal, m)
        end
    end

    return legal
end
