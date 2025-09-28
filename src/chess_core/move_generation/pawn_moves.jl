function _generate_pawn_moves_internal(board::Board, push_fn)
    pawns, start_rank,
    promotion_rank,
    direction,
    enemy_pieces,
    enemy_pawn,
    promo_pieces = board.side_to_move == WHITE ?
                   (board.bitboards[Piece.W_PAWN], 2, 7, 8, Piece.B_PAWN:Piece.B_KING,
        Piece.B_PAWN, (Piece.W_QUEEN, Piece.W_ROOK, Piece.W_BISHOP, Piece.W_KNIGHT)) :
                   (board.bitboards[Piece.B_PAWN], 7, 2, -8, Piece.W_PAWN:Piece.W_KING,
        Piece.W_PAWN, (Piece.B_QUEEN, Piece.B_ROOK, Piece.B_BISHOP, Piece.B_KNIGHT))

    for sq in 0:63
        if !testbit(pawns, sq)
            continue
        end
        file, rank = file_rank(sq)

        # single push
        to_sq = sq + direction
        if on_board(to_sq) &&
           !any(testbit(board.bitboards[p], to_sq) for p in ChessEngine.ALL_PIECES)
            if rank == promotion_rank
                for promo in promo_pieces
                    push_fn(sq, to_sq; promotion = promo)
                end
            else
                push_fn(sq, to_sq)
                # double push
                if rank == start_rank
                    to_sq2 = sq + 2*direction
                    if !any(testbit(board.bitboards[p], to_sq2)
                    for p in ChessEngine.ALL_PIECES)
                        push_fn(sq, to_sq2)
                    end
                end
            end
        end

        # captures
        for delta in (-1, 1)
            to_sq = sq + delta + direction
            if !on_board(to_sq)
                continue
            end
            to_file, _ = file_rank(to_sq)
            if abs(to_file - file) != 1
                continue
            end

            captured = 0
            for p in enemy_pieces
                if testbit(board.bitboards[p], to_sq)
                    captured = p
                    break
                end
            end

            if captured != 0
                if rank == promotion_rank
                    for promo in promo_pieces
                        push_fn(sq, to_sq; capture = captured, promotion = promo)
                    end
                else
                    push_fn(sq, to_sq; capture = captured)
                end
            end

            # en-passant
            if to_sq == board.en_passant
                push_fn(sq, to_sq; capture = enemy_pawn, en_passant = true)
            end
        end
    end
end

"""
Generate pseudo-legal pawn moves for the side to move
- `board`: Board struct
Returns: Vector of Move
"""
function generate_pawn_moves(board::Board)
    moves = Move[]
    _generate_pawn_moves_internal(board, (
        sq, to_sq; kwargs...) -> push!(moves, Move(sq, to_sq; kwargs...)))
    return moves
end

"""
Generate pseudo-legal pawn moves in-place
- `board`: Board struct
- `moves`: preallocated buffer to append moves
Returns: number of moves added
"""
function generate_pawn_moves!(board::Board, moves::Vector{Move})
    len_before = length(moves)
    _generate_pawn_moves_internal(board, (
        sq, to_sq; kwargs...) -> push!(moves, Move(sq, to_sq; kwargs...)))
    return length(moves) - len_before
end
