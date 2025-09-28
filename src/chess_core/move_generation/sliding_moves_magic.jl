# Utility to iterate over set bits in a UInt64
function _iter_bits(bb::UInt64)
    Iterators.flatten((trailing_zeros(bb & (-bb)) for _ in 1:count_ones(bb)))
end

function occupied_bb(board::Board)
    occ = UInt64(0)
    for bb in values(board.bitboards)
        occ |= bb
    end
    return occ
end

"""
Generate pseudo-legal moves for a sliding piece using magic bitboards.
- bb_piece: bitboard of the moving piece
- mask_table, attack_table, magic_table: precomputed tables
- friendly_pieces, enemy_pieces: arrays of piece indices
"""
function generate_sliding_moves_magic(board::Board, bb_piece::UInt64,
        mask_table, attack_table, magic_table)
    moves = Move[]

    friendly_pieces = board.side_to_move == WHITE ?
                      [Piece.W_PAWN, Piece.W_KNIGHT, Piece.W_BISHOP, Piece.W_ROOK, Piece.W_QUEEN, Piece.W_KING] :
                      [Piece.B_PAWN, Piece.B_KNIGHT, Piece.B_BISHOP, Piece.B_ROOK, Piece.B_QUEEN, Piece.B_KING]

    enemy_pieces = board.side_to_move == WHITE ?
                   [Piece.B_PAWN, Piece.B_KNIGHT, Piece.B_BISHOP, Piece.B_ROOK, Piece.B_QUEEN, Piece.B_KING] :
                   [Piece.W_PAWN, Piece.W_KNIGHT, Piece.W_BISHOP, Piece.W_ROOK, Piece.W_QUEEN, Piece.W_KING]

    friendly_bb = UInt64(0)
    for p in friendly_pieces
        friendly_bb |= board.bitboards[p]
    end

    full_occ = occupied_bb(board)

    for sq in 0:63
        if !testbit(bb_piece, sq)
            continue
        end

        println("\n=== square $sq ===")
        println("full_occ (hex)   = ", string(full_occ, base = 16))

        mask = mask_table[sq + 1]
        relevant_bits = count_bits(mask)
        shift = 64 - relevant_bits
        println("mask (hex)       = ", string(mask, base = 16))
        println("relevant_bits    = $relevant_bits  shift = $shift")

        table = attack_table[sq + 1]
        expected_len = UInt(1) << relevant_bits
        println("attack table len = ", length(table), " expected = $expected_len")

        raw_index = ((full_occ & mask) * magic_table[sq + 1]) >> shift
        index_mask = (UInt64(1) << relevant_bits) - UInt64(1)
        idx = Int((raw_index & index_mask) + 1)

        println("magic (hex)      = ", string(magic_table[sq + 1], base = 16))
        println("masked occ (hex) = ", string(full_occ & mask, base = 16))
        println("raw_index (hex)  = ", string(raw_index, base = 16))
        println("idx (1-based)    = $idx")

        @assert 1 <= idx <= length(table)

        attacks = table[idx]
        println("attacks (hex)    = ", string(attacks, base = 16))

        attacks &= ~friendly_bb
        println("after removing friendly (hex) = ", string(attacks, base = 16))

        while attacks != 0
            to_sq = trailing_zeros(attacks)

            capture = 0
            for p in enemy_pieces
                if testbit(board.bitboards[p], to_sq)
                    capture = p
                    break
                end
            end

            println("  -> move $sq → $to_sq capture=$capture")

            push!(moves, Move(sq, to_sq; capture = capture))

            attacks &= attacks - 1
        end
    end

    return moves
end

# In-place variant
function generate_sliding_moves_magic!(board::Board, bb_piece::UInt64,
        mask_table, attack_table, magic_table, moves::Vector{Move})
    len_before = length(moves)

    # Define friendly and enemy pieces
    friendly_pieces = board.side_to_move == WHITE ?
                      [Piece.W_PAWN, Piece.W_KNIGHT, Piece.W_BISHOP, Piece.W_ROOK, Piece.W_QUEEN, Piece.W_KING] :
                      [Piece.B_PAWN, Piece.B_KNIGHT, Piece.B_BISHOP, Piece.B_ROOK, Piece.B_QUEEN, Piece.B_KING]

    enemy_pieces = board.side_to_move == WHITE ?
                   [Piece.B_PAWN, Piece.B_KNIGHT, Piece.B_BISHOP, Piece.B_ROOK, Piece.B_QUEEN, Piece.B_KING] :
                   [Piece.W_PAWN, Piece.W_KNIGHT, Piece.W_BISHOP, Piece.W_ROOK, Piece.W_QUEEN, Piece.W_KING]

    # Compute friendly occupancy
    friendly_bb = UInt64(0)
    for p in friendly_pieces
        friendly_bb |= board.bitboards[p]
    end

    # Loop over all squares for this piece bitboard
    for sq in 0:63
        if !testbit(bb_piece, sq)
            continue
        end

        # Occupancy restricted to mask
        mask = mask_table[sq + 1]
        occ = occupied_bb(board) & mask

        # Magic lookup
        shift = 64 - count_bits(mask)
        index = Int((occ * magic_table[sq + 1]) >> shift) + 1
        attacks = attack_table[sq + 1][index]

        # Iterate over attack squares, stop at blockers
        attack_sq = attacks
        while attack_sq != 0
            to_sq = trailing_zeros(attack_sq)

            # Stop if blocked by friendly piece
            if testbit(friendly_bb, to_sq)
                break
            end

            # Check for capture
            capture = 0
            for p in enemy_pieces
                if testbit(board.bitboards[p], to_sq)
                    capture = p
                    break
                end
            end

            push!(moves, Move(sq, to_sq; capture = capture))

            # Stop if square had any piece (friendly already handled, enemy capture stops ray)
            if capture != 0
                break
            end

            # Clear LSB and continue
            attack_sq &= attack_sq - 1
        end
    end

    return length(moves) - len_before
end

# ========================
# Bishop moves
# ========================
function generate_bishop_moves_magic(board::Board)
    bb = board.side_to_move == WHITE ? board.bitboards[Piece.W_BISHOP] : board.bitboards[Piece.B_BISHOP]
    return generate_sliding_moves_magic(
        board, bb, BISHOP_MASKS, BISHOP_ATTACKS, BISHOP_MAGICS)
end

function generate_bishop_moves_magic!(board::Board, moves::Vector{Move})
    bb = board.side_to_move == WHITE ? board.bitboards[Piece.W_BISHOP] : board.bitboards[Piece.B_BISHOP]
    return generate_sliding_moves_magic!(
        board, bb, BISHOP_MASKS, BISHOP_ATTACKS, BISHOP_MAGICS, moves)
end

# ========================
# Rook moves
# ========================
function generate_rook_moves_magic(board::Board)
    bb = board.side_to_move == WHITE ? board.bitboards[Piece.W_ROOK] : board.bitboards[Piece.B_ROOK]
    return generate_sliding_moves_magic(board, bb, ROOK_MASKS, ROOK_ATTACKS, ROOK_MAGICS)
end

function generate_rook_moves_magic!(board::Board, moves::Vector{Move})
    bb = board.side_to_move == WHITE ? board.bitboards[Piece.W_ROOK] : board.bitboards[Piece.B_ROOK]
    return generate_sliding_moves_magic!(
        board, bb, ROOK_MASKS, ROOK_ATTACKS, ROOK_MAGICS, moves)
end

# ========================
# Queen moves
# ========================
function generate_queen_moves_magic(board::Board)
    bb = board.side_to_move == WHITE ? board.bitboards[Piece.W_QUEEN] : board.bitboards[Piece.B_QUEEN]
    return generate_sliding_moves_magic(board, bb, QUEEN_MASKS, QUEEN_ATTACKS, QUEEN_MAGICS)
end

function generate_queen_moves_magic!(board::Board, moves::Vector{Move})
    bb = board.side_to_move == WHITE ? board.bitboards[Piece.W_QUEEN] : board.bitboards[Piece.B_QUEEN]
    return generate_sliding_moves_magic!(
        board, bb, QUEEN_MASKS, QUEEN_ATTACKS, QUEEN_MAGICS, moves)
end
