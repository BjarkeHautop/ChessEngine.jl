using OrbisChessEngine
using Test

@testset "Bishop mask" begin
    mask_bishop = OrbisChessEngine.bishop_mask_bitcounts()

    @test mask_bishop[1] == 6  # a1
    @test mask_bishop[2] == 5  # b1
    @test mask_bishop[8] == 6  # h1
    @test mask_bishop[28] == 9 # d4
end

@testset "Rook mask" begin
    mask_rook = OrbisChessEngine.rook_mask_bitcounts()

    @test mask_rook[1] == 12  # a1
    @test mask_rook[2] == 11  # b1
    @test mask_rook[3] == 11  # c1
    @test mask_rook[10] == 10  # b2
    @test mask_rook[28] == 10 # d4
end

@testset "Occupancy variations" begin
    # Bishop on a1: mask = b2..g7 (6 bits)
    mask = OrbisChessEngine.bishop_mask(0)
    variations = OrbisChessEngine.occupancy_variations(mask)
    n_bits = count_ones(mask)

    # Number of variations = 2^n
    @test length(variations) == 2^n_bits

    # The first variation has no mask bits set
    @test count_ones(variations[1]) == 0

    # The last variation has all mask bits set
    @test count_ones(variations[end]) == n_bits
end

@testset "BISHOP_ATTACKS basic sanity" begin
    # Example: bishop on a1 (0) on empty board
    sq = 0
    expected = UInt64(0x8040201008040200)  # a1-h8 diagonal
    attacks = OrbisChessEngine.bishop_attack_from_occupancy(sq, 0)
    @test attacks == expected

    # Example: bishop on a1 with blocker on c3
    # c3 = file 3, rank 3 → square_index = (3-1)*8 + (3-1) = 2*8 + 2 = 18
    blocker = UInt64(1) << 18
    occ = blocker
    attacks = OrbisChessEngine.bishop_attack_from_occupancy(sq, occ)

    # a1 bishop can move b2 (index 9) and c3 (index 18), but stops at c3
    expected = (UInt64(1) << 9) | (UInt64(1) << 18)

    @test attacks == expected
end

@testset "ROOK_ATTACKS basic sanity" begin
    # Example: rook on a1 (0) on empty board
    sq = 0
    expected = UInt64(0x01010101010101FE)  # a-file and 1st rank
    attacks = OrbisChessEngine.rook_attack_from_occupancy(sq, 0)
    @test attacks == expected

    # Example: rook on a1 with blocker on a4
    # a4 = file 1, rank 4 → square_index = (4-1)*8 + (1-1) = 3*8 + 0 = 24
    blocker = UInt64(1) << 24
    occ = blocker
    attacks = OrbisChessEngine.rook_attack_from_occupancy(sq, occ)

    # a1 rook can move a2 (index 8), a3 (index 16), and a4 (index 24), but stops at a4
    # and can move along the 1st rank to b1..h1 (indexes 1..7)
    expected = expected = ((UInt64(1) << 1) | (UInt64(1) << 2) | (UInt64(1) << 3) |
                           (UInt64(1) << 4) | (UInt64(1) << 5) | (UInt64(1) << 6) |
                           (UInt64(1) << 7)) |  # b1–h1
                          ((UInt64(1) << 8) | (UInt64(1) << 16) | (UInt64(1) << 24))

    @test attacks == expected
end
