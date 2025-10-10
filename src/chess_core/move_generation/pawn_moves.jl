const pawn_attack_masks = [Vector{UInt64}(undef, 64) for _ in 1:2]  # [WHITE, BLACK]

function init_pawn_masks!()
    for sq in 0:63
        f, r = sq % 8, sq ÷ 8

        # white attacks
        mask_w = zero(UInt64)
        if f > 0 && r < 7
            mask_w |= UInt64(1) << (sq + 7)
        end
        if f < 7 && r < 7
            mask_w |= UInt64(1) << (sq + 9)
        end
        pawn_attack_masks[1][sq + 1] = mask_w

        # black attacks
        mask_b = zero(UInt64)
        if f > 0 && r > 0
            mask_b |= UInt64(1) << (sq - 9)
        end
        if f < 7 && r > 0
            mask_b |= UInt64(1) << (sq - 7)
        end
        pawn_attack_masks[2][sq + 1] = mask_b
    end
end

init_pawn_masks!()

"""
Generate pseudo-legal pawn moves in-place
- `board`: Board struct
- `moves`: preallocated buffer to append moves
Returns: number of moves added
"""
function generate_pawn_moves!(board::Board, moves::Vector{Move})
    # Setup depending on side
    if board.side_to_move == WHITE
        pawns = board.bitboards[Piece.W_PAWN]
        enemy_mask = board.bitboards[Piece.B_PAWN] | board.bitboards[Piece.B_KNIGHT] |
                     board.bitboards[Piece.B_BISHOP] | board.bitboards[Piece.B_ROOK] |
                     board.bitboards[Piece.B_QUEEN] | board.bitboards[Piece.B_KING]
        promo_rank_mask = UInt64(0xFF00000000000000)
        start_rank_mask = UInt64(0x000000000000FF00)
        direction = 8
        left_capture_offset = 7
        right_capture_offset = 9
        promo_pieces = (Piece.W_QUEEN, Piece.W_ROOK, Piece.W_BISHOP, Piece.W_KNIGHT)
        ep_capture_piece = Piece.B_PAWN
    else
        pawns = board.bitboards[Piece.B_PAWN]
        enemy_mask = board.bitboards[Piece.W_PAWN] | board.bitboards[Piece.W_KNIGHT] |
                     board.bitboards[Piece.W_BISHOP] | board.bitboards[Piece.W_ROOK] |
                     board.bitboards[Piece.W_QUEEN] | board.bitboards[Piece.W_KING]
        promo_rank_mask = UInt64(0x00000000000000FF)
        start_rank_mask = UInt64(0x00FF000000000000)
        direction = -8
        left_capture_offset = -9
        right_capture_offset = -7
        promo_pieces = (Piece.B_QUEEN, Piece.B_ROOK, Piece.B_BISHOP, Piece.B_KNIGHT)
        ep_capture_piece = Piece.W_PAWN
    end

    all_occupied = pawns |
                   (board.bitboards[Piece.W_PAWN] | board.bitboards[Piece.W_KNIGHT] |
                    board.bitboards[Piece.W_BISHOP] | board.bitboards[Piece.W_ROOK] |
                    board.bitboards[Piece.W_QUEEN] | board.bitboards[Piece.W_KING] |
                    board.bitboards[Piece.B_PAWN] | board.bitboards[Piece.B_KNIGHT] |
                    board.bitboards[Piece.B_BISHOP] | board.bitboards[Piece.B_ROOK] |
                    board.bitboards[Piece.B_QUEEN] | board.bitboards[Piece.B_KING])

    pawn_bb = pawns
    while pawn_bb != 0
        sq = trailing_zeros(pawn_bb)
        pawn_bb &= pawn_bb - 1

        # single push
        to_sq = sq + direction
        if 0 <= to_sq < 64 && ((all_occupied & (UInt64(1) << to_sq)) == 0)
            if (UInt64(1) << to_sq) & promo_rank_mask != 0
                for promo in promo_pieces
                    push!(moves, Move(Int(sq), Int(to_sq); promotion = promo))
                end
            else
                push!(moves, Move(Int(sq), Int(to_sq)))
            end

            # double push
            if (UInt64(1) << sq) & start_rank_mask != 0
                to_sq2 = sq + 2*direction
                if 0 <= to_sq2 < 64 && (all_occupied & (UInt64(1) << to_sq2)) == 0
                    push!(moves, Move(Int(sq), Int(to_sq2)))
                end
            end
        end

        # captures
        for offset in (left_capture_offset, right_capture_offset)
            # check file boundaries
            file_ok = (offset in (left_capture_offset,) && sq % 8 != 0) ||
                      (offset in (right_capture_offset,) && sq % 8 != 7)
            if file_ok
                to_sq = sq + offset
                if 0 <= to_sq < 64 && (enemy_mask & (UInt64(1) << to_sq)) != 0
                    capture_piece = find_capture_piece(
                        board, to_sq,
                        board.side_to_move == WHITE ? Piece.B_PAWN : Piece.W_PAWN,
                        board.side_to_move == WHITE ? Piece.B_KING : Piece.W_KING
                    )
                    if (UInt64(1) << to_sq) & promo_rank_mask != 0
                        for promo in promo_pieces
                            push!(moves,
                                Move(Int(sq), Int(to_sq); capture = capture_piece, promotion = promo))
                        end
                    else
                        push!(moves, Move(Int(sq), Int(to_sq); capture = capture_piece))
                    end
                end
            end
        end

        # en passant
        if board.en_passant != -1
            ep_sq = board.en_passant
            if (sq % 8 != 0 && sq + left_capture_offset == ep_sq) ||
               (sq % 8 != 7 && sq + right_capture_offset == ep_sq)
                push!(moves, Move(Int(sq), Int(ep_sq); capture = ep_capture_piece, en_passant = true))
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
    generate_pawn_moves!(board, moves)
    return moves
end
