# Generate magic numbers once and save them to a file.

using Serialization

# BISHOP_MAGICS = ChessEngine.generate_magics(ChessEngine.BISHOP_MASKS, ChessEngine.bishop_attack_from_occupancy)
# ROOK_MAGICS = ChessEngine.generate_magics(ChessEngine.ROOK_MASKS, ChessEngine.rook_attack_from_occupancy)
# QUEEN_MAGICS = ChessEngine.generate_magics(ChessEngine.QUEEN_MASKS, ChessEngine.queen_attack_from_occupancy)

# Save them
# serialize(joinpath(ChessEngine.ASSET_DIR, "bishop_magics.bin"), BISHOP_MAGICS)
# serialize(joinpath(ChessEngine.ASSET_DIR, "rook_magics.bin"), ROOK_MAGICS)
# serialize(joinpath(ChessEngine.ASSET_DIR, "queen_magics.bin"), QUEEN_MAGICS)

# Load them
const BISHOP_MAGICS = deserialize(joinpath(ChessEngine.ASSET_DIR, "bishop_magics.bin"))
const ROOK_MAGICS = deserialize(joinpath(ChessEngine.ASSET_DIR, "rook_magics.bin"))
const QUEEN_MAGICS = deserialize(joinpath(ChessEngine.ASSET_DIR, "queen_magics.bin"))
