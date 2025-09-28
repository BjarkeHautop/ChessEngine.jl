######################### # Square / bit helpers # ######################### 
"Map (file, rank) → square index (0..63). file=1→a, rank=1→1."
square_index(file, rank) = (rank - 1) * 8 + (file - 1)

"Map algebraic notation (e.g. 'e3') → square index (0..63)."
function square_index(sq::AbstractString)
    file_char, rank_char = sq[1], sq[2]   # e.g. "e3" → 'e', '3'
    file = Int(file_char) - Int('a') + 1  # 'a' → 1, 'b' → 2, ...
    rank = parse(Int, string(rank_char))  # '3' → 3
    return (rank - 1) * 8 + (file - 1)
end

"Set bit at square sq."
setbit(bb, sq) = bb | (UInt64(1) << sq)

"Clear bit at square sq."
clearbit(bb, sq) = bb & ~(UInt64(1) << sq)

"Check if bit at square sq is set."
testbit(bb, sq) = ((bb >> sq) & 0x1) == 1
