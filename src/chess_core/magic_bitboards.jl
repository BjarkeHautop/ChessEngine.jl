"""
For a given square, return the bishop mask for magic bitboards:
all squares along its diagonals, **excluding the edges**.
This is used for occupancy/magic table generation.
"""
function bishop_mask(sq)
    mask = UInt64(0)
    f, r = file_rank(sq)
    directions = [(-1, -1), (-1, 1), (1, -1), (1, 1)]

    for (df, dr) in directions
        nf, nr = f + df, r + dr
        # move along the diagonal until one square before the edge
        while 1 < nf < 8 && 1 < nr < 8
            mask |= UInt64(1) << square_index(nf, nr)
            nf += df
            nr += dr
        end
    end

    return mask
end

"""
Count the number of bits set in a UInt64.
"""
count_bits(bb::UInt64) = count_ones(bb)

"""
Compute number of bits in the bishop mask for each square.
Returns a 64-element array of integers.
"""
function bishop_mask_bitcounts()
    masks = [bishop_mask(sq) for sq in 0:63]
    return [count_bits(mask) for mask in masks]
end


"""
Generate all possible occupancy bitboards for the given mask
"""
function occupancy_variations(mask)
    bits = findall(i -> testbit(mask, i), 0:63)
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
Compute bishop attacks from a square given an occupancy
"""
function bishop_attack_from_occupancy(sq, occ)
    attacks = UInt64(0)
    f, r = file_rank(sq)
    directions = [(-1, -1), (-1, 1), (1, -1), (1, 1)]

    for (df, dr) in directions
        nf, nr = f + df, r + dr
        while 1 <= nf <= 8 && 1 <= nr <= 8
            idx = square_index(nf, nr)
            attacks |= UInt64(1) << idx
            # Stop if blocked
            if testbit(occ, idx)
                break
            end
            nf += df
            nr += dr
        end
    end
    return attacks
end

# Build bishop attack tables
BISHOP_MASKS = [bishop_mask(sq) for sq in 0:63]
BISHOP_ATTACKS = Vector{Vector{UInt64}}(undef, 64)

for sq in 0:63
    occs = occupancy_variations(BISHOP_MASKS[sq+1])
    BISHOP_ATTACKS[sq+1] = [bishop_attack_from_occupancy(sq, occ) for occ in occs]
end

using Random

"""
Try to find a magic number for a given square.
- sq: square index 0–63
- tries: number of random candidates to attempt
"""
function find_bishop_magic(sq; tries::Int=100_000_000)
    mask = BISHOP_MASKS[sq+1]
    bits = findall(i -> testbit(mask, i), 0:63)
    n = length(bits)
    shift = 64 - n

    # Generate all occupancies and their attacks
    occs = occupancy_variations(mask)
    attacks = [bishop_attack_from_occupancy(sq, occ) for occ in occs]

    print("  mask has $n bits … ")
    for _ in 1:tries
        # Generate a random sparse number
        magic = rand(UInt64) & rand(UInt64) & rand(UInt64)

        # Skip bad magics (too few bits set)
        if count_ones((mask * magic) & 0xFF00000000000000) < 6
            continue
        end

        used = Dict{Int,UInt64}()
        success = true

        for (occ, attack) in zip(occs, attacks)
            idx = Int((occ * magic) >> shift)
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
Compute bishop magics for all squares
"""
function generate_bishop_magics()
    Random.seed!(1405) 
    magics = Vector{UInt64}(undef, 64)
    for sq in 0:63
        println("Finding magic for square $sq …")
        magics[sq+1] = find_bishop_magic(sq)
        println("  found: ", string(magics[sq+1], base=16))
    end
    return magics
end

# const BISHOP_MAGICS = generate_bishop_magics()


"""
For a given square, return the rook mask for magic bitboards:
all squares along its rank and file, excluding the edges.
"""
function rook_mask(sq)
    mask = UInt64(0)
    f, r = file_rank(sq)

    # Occupancy along the file (same column)
    for nr in 2:7
        if nr != r
            mask |= UInt64(1) << square_index(f, nr)
        end
    end

    # Occupancy along the rank (same row)
    for nf in 2:7
        if nf != f
            mask |= UInt64(1) << square_index(nf, r)
        end
    end

    return mask
end

"""
Compute rook attacks from a square given an occupancy
"""
function rook_attack_from_occupancy(sq, occ)
    attacks = UInt64(0)
    f, r = file_rank(sq)
    directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]

    for (df, dr) in directions
        nf, nr = f + df, r + dr
        while 1 <= nf <= 8 && 1 <= nr <= 8
            idx = square_index(nf, nr)
            attacks |= UInt64(1) << idx
            # Stop if blocked
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
Compute number of bits in the rook mask for each square.
Returns a 64-element array of integers.
"""
function rook_mask_bitcounts()
    masks = [rook_mask(sq) for sq in 0:63]
    return [count_bits(mask) for mask in masks]
end

# Build rook attack tables
ROOK_MASKS = [rook_mask(sq) for sq in 0:63]
ROOK_ATTACKS = Vector{Vector{UInt64}}(undef, 64)

for sq in 0:63
    occs = occupancy_variations(ROOK_MASKS[sq+1])
    ROOK_ATTACKS[sq+1] = [rook_attack_from_occupancy(sq, occ) for occ in occs]
end

"""
Try to find a magic number for a given rook square
"""
function find_rook_magic(sq; tries::Int=100_000_000)
    mask = ROOK_MASKS[sq+1]
    bits = findall(i -> testbit(mask, i), 0:63)
    n = length(bits)
    shift = 64 - n

    occs = occupancy_variations(mask)
    attacks = [rook_attack_from_occupancy(sq, occ) for occ in occs]

    print("  mask has $n bits … ")
    for _ in 1:tries
        magic = rand(UInt64) & rand(UInt64) & rand(UInt64)

        if count_ones((mask * magic) & 0xFF00000000000000) < 6
            continue
        end

        used = Dict{Int,UInt64}()
        success = true

        for (occ, attack) in zip(occs, attacks)
            idx = Int((occ * magic) >> shift)
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
Compute rook magics for all squares
"""
function generate_rook_magics()
    Random.seed!(1405) 
    magics = Vector{UInt64}(undef, 64)
    for sq in 0:63
        println("Finding magic for square $sq …")
        magics[sq+1] = find_rook_magic(sq)
        println("  found: ", string(magics[sq+1], base=16))
    end
    return magics
end

# const ROOK_MAGICS = generate_rook_magics()
