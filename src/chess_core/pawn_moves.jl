"""
Generate pseudo-legal pawn moves for the side to move
- `board`: Board struct
Returns: Vector of Move
"""
function generate_pawn_moves(board::Board)
    moves = Move[]

    if board.side_to_move == WHITE
        pawns = board.bitboards[W_PAWN]
        start_rank = 2
        promotion_rank = 7
        direction = 8
        enemy_pieces = B_PAWN:B_KING
        enemy_pawn = B_PAWN
        promo_pieces = (W_QUEEN, W_ROOK, W_BISHOP, W_KNIGHT)
    else
        pawns = board.bitboards[B_PAWN]
        start_rank = 7
        promotion_rank = 2
        direction = -8
        enemy_pieces = W_PAWN:W_KING
        enemy_pawn = W_PAWN
        promo_pieces = (B_QUEEN, B_ROOK, B_BISHOP, B_KNIGHT)
    end

    for sq in 0:63
        if !testbit(pawns, sq)
            continue
        end

        file, rank = file_rank(sq)

        # single push
        to_sq = sq + direction
        if on_board(to_sq) && !any(testbit(board.bitboards[p], to_sq) for p in ALL_PIECES)
            if rank == promotion_rank
                # generate promotion moves
                for promo in promo_pieces
                    push!(moves, Move(sq, to_sq; promotion = promo))
                end
            else
                push!(moves, Move(sq, to_sq))

                # double push from start rank
                if rank == start_rank
                    to_sq2 = sq + 2*direction
                    if !any(testbit(board.bitboards[p], to_sq2) for p in ALL_PIECES)
                        push!(moves, Move(sq, to_sq2))
                    end
                end
            end
        end

        # captures
        for delta in (-1, 1)
            to_sq = sq + delta + direction
            if on_board(to_sq)
                to_file, _ = file_rank(to_sq)
                if abs(to_file - file) != 1
                    continue  # skip wraparound captures
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
                            push!(moves, Move(sq, to_sq; capture = captured, promotion = promo))
                        end
                    else
                        push!(moves, Move(sq, to_sq; capture = captured))
                    end
                end

                if to_sq == board.en_passant
                    push!(moves, Move(sq, to_sq; capture = enemy_pawn, en_passant = true))
                end
            end
        end
    end

    return moves
end
