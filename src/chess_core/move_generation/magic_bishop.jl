"""
    new_file_rank(sq) -> (Int, Int)

Return file (1..8) and rank (1..8) for a square index
"""
new_file_rank(sq) = (sq % 8 + 1, sq ÷ 8 + 1)

"Map (file, rank) → square index (0..63). file=1→a, rank=1→1."
new_square_index(file, rank) = (rank - 1) * 8 + (file - 1)

"""
Generic sliding mask generator.
- sq: square index (0..63)
- directions: list of (df, dr) directions
"""
function new_sliding_mask(sq, directions)
    mask = UInt64(0)
    f, r = new_file_rank(sq)
    for (df, dr) in directions
        nf, nr = f + df, r + dr
        while 1 < nf < 8 && 1 < nr < 8
            mask |= UInt64(1) << new_square_index(nf, nr)
            nf += df
            nr += dr
        end
    end
    return mask
end

"""
Generic sliding attack generator.
- sq: square index
- occ: occupancy bitboard
- directions: list of (df, dr) directions
"""
function new_sliding_attack_from_occupancy(sq, occ, directions)
    attacks = UInt64(0)
    f, r = new_file_rank(sq)

    for (df, dr) in directions
        nf, nr = f + df, r + dr
        while 1 <= nf <= 8 && 1 <= nr <= 8
            idx = new_square_index(nf, nr)
            attacks |= UInt64(1) << idx
            if testbit(occ, idx)
                break
            end
            nf += df
            nr += dr
        end
    end
    return attacks
end

"""
Generate all possible occupancy bitboards for the given mask
"""
function new_occupancy_variations(mask)
    bits = [i for i in 0:63 if testbit(mask, i)]   # actual square indices 0..63
    n = length(bits)
    variations = UInt64[]
    for i in 0:(2^n - 1)
        occ = UInt64(0)
        for j in 1:n
            if i & (1 << (j - 1)) != 0
                occ |= UInt64(1) << bits[j]
            end
        end
        push!(variations, occ)
    end
    return variations
end

"""
Count the number of bits set in a UInt64.
"""
new_count_bits(bb::UInt64) = count_ones(bb)

using Random

"""
Try to find a magic number for a given square.
- sq: square index 0–63
- masks: precomputed mask table (bishop or rook)
- attack_fn: function (sq, occ) → attacks
- tries: number of random candidates to attempt
"""
function new_find_magic(sq, masks, attack_fn; tries::Int = 10_000_000_000)
    mask = masks[sq + 1]
    n = count_ones(mask)
    shift = 64 - n

    # Generate all occupancies and their attacks
    occs = new_occupancy_variations(mask)
    attacks = [attack_fn(sq, occ) for occ in occs]

    for _ in 1:tries
        # Generate a random sparse number
        magic = rand(UInt64) & rand(UInt64) & rand(UInt64)

        # Skip bad magics (too few bits set in high region)
        if count_ones(magic & 0xFF00000000000000) < 6
            continue
        end

        used = Dict{Int, UInt64}()
        success = true

        for (occ, attack) in zip(occs, attacks)
            idx = Int(((occ * magic) & 0xFFFFFFFFFFFFFFFF) >> shift)
            if haskey(used, idx)
                if used[idx] != attack
                    success = false
                    break
                end
            else
                used[idx] = attack
            end
        end

        if success
            return magic
        end
    end
    println("Failed to find magic for square $sq after $tries tries")
    # Set it to a default value to avoid errors
    return UInt64(0)
end

"""
Compute magic numbers for all squares.
- masks: precomputed mask table (bishop or rook)
- attack_fn: function (sq, occ) → attacks
"""
function new_generate_magics(masks, attack_fn)
    Random.seed!(1405)
    magics = Vector{UInt64}(undef, 64)
    for sq in 0:63
        magics[sq + 1] = new_find_magic(sq, masks, attack_fn)
    end
    return magics
end

# Bishop-specific
const new_BISHOP_DIRECTIONS = [(-1, -1), (-1, 1), (1, -1), (1, 1)]
new_bishop_mask(sq) = new_sliding_mask(sq, new_BISHOP_DIRECTIONS)
function new_bishop_attack_from_occupancy(sq, occ)
    new_sliding_attack_from_occupancy(sq, occ, new_BISHOP_DIRECTIONS)
end

function new_bishop_mask_bitcounts()
    masks = [new_bishop_mask(sq) for sq in 0:63]
    return [new_count_bits(mask) for mask in masks]
end

new_BISHOP_MASKS = [new_bishop_mask(sq) for sq in 0:63]
new_BISHOP_ATTACKS = Vector{Vector{UInt64}}(undef, 64)

for sq in 0:63
    occs = new_occupancy_variations(new_BISHOP_MASKS[sq + 1])
    new_BISHOP_ATTACKS[sq + 1] = [new_bishop_attack_from_occupancy(sq, occ) for occ in occs]
end

const new_BISHOP_MAGICS = new_generate_magics(new_BISHOP_MASKS, new_bishop_attack_from_occupancy)

# Build magic attack tables properly
new_BISHOP_ATTACK_TABLES = Vector{Vector{UInt64}}(undef, 64)

for sq in 0:63
    mask = new_BISHOP_MASKS[sq + 1]
    n = count_ones(mask)
    shift = 64 - n
    table_size = 1 << n
    
    table = zeros(UInt64, table_size)
    occs = new_occupancy_variations(mask)
    
    for occ in occs
        magic = new_BISHOP_MAGICS[sq + 1]
        idx = Int(((occ * magic) >> shift)) + 1
        attack = new_bishop_attack_from_occupancy(sq, occ)
        table[idx] = attack
    end
    
    new_BISHOP_ATTACK_TABLES[sq + 1] = table
end

# Utility to iterate over set bits in a UInt64
function new__iter_bits(bb::UInt64)
    idxs = Int[]
    while bb != 0
        tz = trailing_zeros(bb)
        push!(idxs, tz)
        bb &= bb - 1
    end
    return idxs
end

function new_occupied_bb(board::Board)
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
function new_generate_sliding_moves_magic(board::Board, bb_piece::UInt64,
        mask_table, attack_table, magic_table)
    moves = Move[]

    friendly_pieces = board.side_to_move == WHITE ?
                      [Piece.W_PAWN, Piece.W_KNIGHT, Piece.W_BISHOP,
        Piece.W_ROOK, Piece.W_QUEEN, Piece.W_KING] :
                      [Piece.B_PAWN, Piece.B_KNIGHT, Piece.B_BISHOP,
        Piece.B_ROOK, Piece.B_QUEEN, Piece.B_KING]

    enemy_pieces = board.side_to_move == WHITE ?
                   [Piece.B_PAWN, Piece.B_KNIGHT, Piece.B_BISHOP,
        Piece.B_ROOK, Piece.B_QUEEN, Piece.B_KING] :
                   [Piece.W_PAWN, Piece.W_KNIGHT, Piece.W_BISHOP,
        Piece.W_ROOK, Piece.W_QUEEN, Piece.W_KING]

    friendly_bb = UInt64(0)
    for p in friendly_pieces
        friendly_bb |= board.bitboards[p]
    end

    full_occ = new_occupied_bb(board)

    for sq in 0:63
        if !testbit(bb_piece, sq)
            continue
        end

        mask = mask_table[sq + 1]
        relevant_bits = new_count_bits(mask)
        shift = 64 - relevant_bits

        table = attack_table[sq + 1]

        idx = Int((((full_occ & mask) * magic_table[sq + 1]) >> shift) + 1)

        @assert 1 <= idx <= length(table)

        attacks = table[idx]

        attacks &= ~friendly_bb

        while attacks != 0
            to_sq = trailing_zeros(attacks)

            capture = 0
            for p in enemy_pieces
                if testbit(board.bitboards[p], to_sq)
                    capture = p
                    break
                end
            end

            push!(moves, Move(sq, to_sq; capture = capture))
            attacks &= attacks - 1
        end
    end

    return moves
end

function new_generate_bishop_moves_magic(board::Board)
    bb = board.side_to_move == WHITE ? board.bitboards[Piece.W_BISHOP] :
         board.bitboards[Piece.B_BISHOP]
    return new_generate_sliding_moves_magic(
        board, bb, new_BISHOP_MASKS, new_BISHOP_ATTACK_TABLES, new_BISHOP_MAGICS)
end
