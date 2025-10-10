# Internal helper for king moves
# `push_fn` is a function used to append a move
function _king_moves_internal(board::Board, push_fn)
    if board.side_to_move == WHITE
        kings = board.bitboards[Piece.W_KING]
        friendly_pieces = Piece.W_PAWN:Piece.W_KING
        enemy_pieces = Piece.B_PAWN:Piece.B_KING
        rights = board.castling_rights
        king_sq = 4   # e1
    else
        kings = board.bitboards[Piece.B_KING]
        friendly_pieces = Piece.B_PAWN:Piece.B_KING
        enemy_pieces = Piece.W_PAWN:Piece.W_KING
        rights = board.castling_rights
        king_sq = 60  # e8
    end

    # Build bitboard of all friendly pieces
    occupied_friendly = zero(UInt64)
    for p in friendly_pieces
        occupied_friendly |= board.bitboards[p]
    end

    # King move offsets (one square in any direction)
    deltas = [-9, -8, -7, -1, 1, 7, 8, 9]

    for sq in 0:63
        if !testbit(kings, sq)
            continue
        end

        f, r = file_rank(sq)

        for d in deltas
            to_sq = sq + d
            if !on_board(to_sq)
                continue
            end

            tf, tr = file_rank(to_sq)
            if abs(tf - f) <= 1 && abs(tr - r) <= 1
                if !testbit(occupied_friendly, to_sq)
                    # Check for capture
                    capture = 0
                    for p in enemy_pieces
                        if testbit(board.bitboards[p], to_sq)
                            capture = p
                            break
                        end
                    end
                    push_fn(sq, to_sq; capture = capture)
                end
            end
        end

        # Castling (pseudo-legal)
        if board.side_to_move == WHITE
            if testbit(kings, 4)
                # White kingside (K)
                if (rights & 0b0001) != 0 &&
                   !any(
                    testbit(board.bitboards[p], 5) || testbit(board.bitboards[p], 6)
                for p in ALL_PIECES
                )
                    push_fn(4, 6; castling = 1)
                end
                # White queenside (Q)
                if (rights & 0b0010) != 0 &&
                   !any(
                    testbit(board.bitboards[p], 1) ||
                    testbit(board.bitboards[p], 2) ||
                    testbit(board.bitboards[p], 3)
                for p in ALL_PIECES
                )
                    push_fn(4, 2; castling = 2)
                end
            end
        else
            if testbit(kings, 60)
                # Black kingside (k)
                if (rights & 0b0100) != 0 &&
                   !any(
                    testbit(board.bitboards[p], 61) || testbit(board.bitboards[p], 62)
                for p in ALL_PIECES
                )
                    push_fn(60, 62; castling = 1)
                end
                # Black queenside (q)
                if (rights & 0b1000) != 0 &&
                   !any(
                    testbit(board.bitboards[p], 57) ||
                    testbit(board.bitboards[p], 58) ||
                    testbit(board.bitboards[p], 59)
                for p in ALL_PIECES
                )
                    push_fn(60, 58; castling = 2)
                end
            end
        end
    end
end

# Return a vector
function generate_king_moves(board::Board)
    moves = Move[]
    _king_moves_internal(board, (
        from, to; kwargs...) -> push!(moves, Move(from, to; kwargs...)))
    return moves
end

# Fill an existing vector
function generate_king_moves_old!(board::Board, moves::Vector{Move})
    len_before = length(moves)
    _king_moves_internal(board, (
        from, to; kwargs...) -> push!(moves, Move(from, to; kwargs...)))
    return length(moves) - len_before
end

# Precompute king moves for all 64 squares
const king_attack_masks = Vector{UInt64}(undef, 64)

function init_king_masks!()
    for sq in 0:63
        mask = zero(UInt64)
        f, r = sq % 8, sq ÷ 8
        for df in -1:1
            for dr in -1:1
                if df == 0 && dr == 0
                    continue
                end
                nf, nr = f + df, r + dr
                if 0 ≤ nf < 8 && 0 ≤ nr < 8
                    mask |= UInt64(1) << (nr * 8 + nf)
                end
            end
        end
        king_attack_masks[sq + 1] = mask
    end
end

# Initialize once
init_king_masks!()

# Zero-allocation king move generation
function generate_king_moves!(board::Board, moves::Vector{Move})
    # Choose correct side bitboards
    if board.side_to_move == WHITE
        kings = board.bitboards[Piece.W_KING]
        friendly_mask = board.bitboards[Piece.W_PAWN] | board.bitboards[Piece.W_KNIGHT] |
                        board.bitboards[Piece.W_BISHOP] | board.bitboards[Piece.W_ROOK] |
                        board.bitboards[Piece.W_QUEEN] | board.bitboards[Piece.W_KING]
        enemy_mask = board.bitboards[Piece.B_PAWN] | board.bitboards[Piece.B_KNIGHT] |
                     board.bitboards[Piece.B_BISHOP] | board.bitboards[Piece.B_ROOK] |
                     board.bitboards[Piece.B_QUEEN] | board.bitboards[Piece.B_KING]
        enemy_range = Piece.B_PAWN:Piece.B_KING
        rights = board.castling_rights
        king_sq = trailing_zeros(kings)
    else
        kings = board.bitboards[Piece.B_KING]
        friendly_mask = board.bitboards[Piece.B_PAWN] | board.bitboards[Piece.B_KNIGHT] |
                        board.bitboards[Piece.B_BISHOP] | board.bitboards[Piece.B_ROOK] |
                        board.bitboards[Piece.B_QUEEN] | board.bitboards[Piece.B_KING]
        enemy_mask = board.bitboards[Piece.W_PAWN] | board.bitboards[Piece.W_KNIGHT] |
                     board.bitboards[Piece.W_BISHOP] | board.bitboards[Piece.W_ROOK] |
                     board.bitboards[Piece.W_QUEEN] | board.bitboards[Piece.W_KING]
        enemy_range = Piece.W_PAWN:Piece.W_KING
        rights = board.castling_rights
        king_sq = trailing_zeros(kings)
    end

    # Regular king moves
    attacks = king_attack_masks[king_sq + 1] & ~friendly_mask
    attack_bb = attacks
    while attack_bb != 0
        to_sq = trailing_zeros(attack_bb)
        attack_bb &= attack_bb - 1

        capture = 0
        if enemy_mask & (UInt64(1) << to_sq) != 0
            for p in enemy_range
                if board.bitboards[p] & (UInt64(1) << to_sq) != 0
                    capture = p
                    break
                end
            end
        end

        push!(moves, Move(king_sq, to_sq; capture=capture))
    end

    # =============== Castling (pseudo-legal) ===============
    occupied_mask = friendly_mask | enemy_mask
    if board.side_to_move == WHITE
        if (rights & 0b0001) != 0 &&
           ( (occupied_mask & ((UInt64(1) << 5) | (UInt64(1) << 6))) == 0 )
            push!(moves, Move(4, 6; castling=1))
        end
        if (rights & 0b0010) != 0 &&
           ( (occupied_mask & ((UInt64(1) << 1) | (UInt64(1) << 2) | (UInt64(1) << 3))) == 0 )
            push!(moves, Move(4, 2; castling=2))
        end
    else
        if (rights & 0b0100) != 0 &&
           ( (occupied_mask & ((UInt64(1) << 61) | (UInt64(1) << 62))) == 0 )
            push!(moves, Move(60, 62; castling=1))
        end
        if (rights & 0b1000) != 0 &&
           ( (occupied_mask & ((UInt64(1) << 57) | (UInt64(1) << 58) | (UInt64(1) << 59))) == 0 )
            push!(moves, Move(60, 58; castling=2))
        end
    end
end

