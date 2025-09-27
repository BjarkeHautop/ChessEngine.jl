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

    # Define friendly and enemy pieces
    friendly_pieces = board.side_to_move == WHITE ?
                      [W_PAWN, W_KNIGHT, W_BISHOP, W_ROOK, W_QUEEN, W_KING] :
                      [B_PAWN, B_KNIGHT, B_BISHOP, B_ROOK, B_QUEEN, B_KING]

    enemy_pieces = board.side_to_move == WHITE ?
                   [B_PAWN, B_KNIGHT, B_BISHOP, B_ROOK, B_QUEEN, B_KING] :
                   [W_PAWN, W_KNIGHT, W_BISHOP, W_ROOK, W_QUEEN, W_KING]

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

    return moves
end

# In-place variant
function generate_sliding_moves_magic!(board::Board, bb_piece::UInt64,
        mask_table, attack_table, magic_table, moves::Vector{Move})
    len_before = length(moves)

    # Define friendly and enemy pieces
    friendly_pieces = board.side_to_move == WHITE ?
                      [W_PAWN, W_KNIGHT, W_BISHOP, W_ROOK, W_QUEEN, W_KING] :
                      [B_PAWN, B_KNIGHT, B_BISHOP, B_ROOK, B_QUEEN, B_KING]

    enemy_pieces = board.side_to_move == WHITE ?
                   [B_PAWN, B_KNIGHT, B_BISHOP, B_ROOK, B_QUEEN, B_KING] :
                   [W_PAWN, W_KNIGHT, W_BISHOP, W_ROOK, W_QUEEN, W_KING]

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
    bb = board.side_to_move == WHITE ? board.bitboards[W_BISHOP] : board.bitboards[B_BISHOP]
    return generate_sliding_moves_magic(
        board, bb, BISHOP_MASKS, BISHOP_ATTACKS, BISHOP_MAGICS)
end

function generate_bishop_moves_magic!(board::Board, moves::Vector{Move})
    bb = board.side_to_move == WHITE ? board.bitboards[W_BISHOP] : board.bitboards[B_BISHOP]
    return generate_sliding_moves_magic!(
        board, bb, BISHOP_MASKS, BISHOP_ATTACKS, BISHOP_MAGICS, moves)
end

# ========================
# Rook moves
# ========================
function generate_rook_moves_magic(board::Board)
    bb = board.side_to_move == WHITE ? board.bitboards[W_ROOK] : board.bitboards[B_ROOK]
    return generate_sliding_moves_magic(board, bb, ROOK_MASKS, ROOK_ATTACKS, ROOK_MAGICS)
end

function generate_rook_moves_magic!(board::Board, moves::Vector{Move})
    bb = board.side_to_move == WHITE ? board.bitboards[W_ROOK] : board.bitboards[B_ROOK]
    return generate_sliding_moves_magic!(
        board, bb, ROOK_MASKS, ROOK_ATTACKS, ROOK_MAGICS, moves)
end

# ========================
# Queen moves
# ========================
function generate_queen_moves_magic(board::Board)
    bb = board.side_to_move == WHITE ? board.bitboards[W_QUEEN] : board.bitboards[B_QUEEN]
    return generate_sliding_moves_magic(board, bb, QUEEN_MASKS, QUEEN_ATTACKS, QUEEN_MAGICS)
end

function generate_queen_moves_magic!(board::Board, moves::Vector{Move})
    bb = board.side_to_move == WHITE ? board.bitboards[W_QUEEN] : board.bitboards[B_QUEEN]
    return generate_sliding_moves_magic!(
        board, bb, QUEEN_MASKS, QUEEN_ATTACKS, QUEEN_MAGICS, moves)
end
