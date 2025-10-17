"""
Generic sliding mask generator.
- sq: square index (0..63)
- directions: list of (df, dr) directions
"""
function sliding_mask(sq, directions)
    mask = UInt64(0)
    f, r = file_rank(sq)
    for (df, dr) in directions
        nf, nr = f + df, r + dr
        while 1 < nf < 8 && 1 < nr < 8
            mask |= UInt64(1) << square_index(nf, nr)
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
function sliding_attack_from_occupancy(sq, occ, directions)
    attacks = UInt64(0)
    f, r = file_rank(sq)

    for (df, dr) in directions
        nf, nr = f + df, r + dr
        while 1 <= nf <= 8 && 1 <= nr <= 8
            idx = square_index(nf, nr)
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
function occupancy_variations(mask)
    bits = findall(i -> testbit(mask, i), 0:63)
    n = length(bits)
    variations = UInt64[]
    for i in 0:(2 ^ n - 1)
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
count_bits(bb::UInt64) = count_ones(bb)

using Random

"""
Try to find a magic number for a given square.
- sq: square index 0–63
- masks: precomputed mask table (bishop or rook)
- attack_fn: function (sq, occ) → attacks
- tries: number of random candidates to attempt
"""
function find_magic(sq, masks, attack_fn; tries::Int = 100_000_000)
    mask = masks[sq + 1]
    n = count_ones(mask)
    shift = 64 - n

    # Generate all occupancies and their attacks
    occs = occupancy_variations(mask)
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

    error("Failed to find magic for square $sq after $tries tries")
end

"""
Compute magic numbers for all squares.
- masks: precomputed mask table (bishop or rook)
- attack_fn: function (sq, occ) → attacks
"""
function generate_magics(masks, attack_fn)
    Random.seed!(1405)
    magics = Vector{UInt64}(undef, 64)
    for sq in 0:63
        magics[sq + 1] = find_magic(sq, masks, attack_fn)
    end
    return magics
end

# Bishop-specific
const BISHOP_DIRECTIONS = [(-1, -1), (-1, 1), (1, -1), (1, 1)]
bishop_mask(sq) = sliding_mask(sq, BISHOP_DIRECTIONS)
function bishop_attack_from_occupancy(sq, occ)
    sliding_attack_from_occupancy(sq, occ, BISHOP_DIRECTIONS)
end

function bishop_mask_bitcounts()
    masks = [bishop_mask(sq) for sq in 0:63]
    return [count_bits(mask) for mask in masks]
end

BISHOP_MASKS = [bishop_mask(sq) for sq in 0:63]
BISHOP_ATTACKS = Vector{Vector{UInt64}}(undef, 64)

for sq in 0:63
    occs = occupancy_variations(BISHOP_MASKS[sq + 1])
    BISHOP_ATTACKS[sq + 1] = [bishop_attack_from_occupancy(sq, occ) for occ in occs]
end

# Rook-specific
const ROOK_DIRECTIONS = [(-1, 0), (1, 0), (0, -1), (0, 1)]
rook_mask(sq) = sliding_mask(sq, ROOK_DIRECTIONS)
function rook_attack_from_occupancy(sq, occ)
    sliding_attack_from_occupancy(sq, occ, ROOK_DIRECTIONS)
end

function rook_mask_bitcounts()
    masks = [rook_mask(sq) for sq in 0:63]
    return [count_bits(mask) for mask in masks]
end

ROOK_MASKS = [rook_mask(sq) for sq in 0:63]
ROOK_ATTACKS = Vector{Vector{UInt64}}(undef, 64)

for sq in 0:63
    occs = occupancy_variations(ROOK_MASKS[sq + 1])
    ROOK_ATTACKS[sq + 1] = [rook_attack_from_occupancy(sq, occ) for occ in occs]
end

# Queen-specific (rook + bishop)

const QUEEN_DIRECTIONS = vcat(ROOK_DIRECTIONS, BISHOP_DIRECTIONS)

queen_mask(sq) = sliding_mask(sq, QUEEN_DIRECTIONS)
function queen_attack_from_occupancy(sq, occ)
    sliding_attack_from_occupancy(sq, occ, QUEEN_DIRECTIONS)
end

function queen_mask_bitcounts()
    masks = [queen_mask(sq) for sq in 0:63]
    return [count_bits(mask) for mask in masks]
end

# Precompute masks and attacks for queens
QUEEN_MASKS = [queen_mask(sq) for sq in 0:63]
QUEEN_ATTACKS = Vector{Vector{UInt64}}(undef, 64)

for sq in 0:63
    occs = occupancy_variations(QUEEN_MASKS[sq + 1])
    QUEEN_ATTACKS[sq + 1] = [queen_attack_from_occupancy(sq, occ) for occ in occs]
end

const BISHOP_MAGICS_new = generate_magics(BISHOP_MASKS, bishop_attack_from_occupancy)
const ROOK_MAGICS_new = generate_magics(ROOK_MASKS, rook_attack_from_occupancy)
const QUEEN_MAGICS_new = generate_magics(QUEEN_MASKS, queen_attack_from_occupancy)