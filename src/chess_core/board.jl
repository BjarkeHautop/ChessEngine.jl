########################
# Piece type constants #
########################

@enum Side WHITE=0 BLACK=1

opposite(side::Side)::Side = side == WHITE ? BLACK : WHITE

# White pieces
const W_PAWN = 1
const W_KNIGHT = 2
const W_BISHOP = 3
const W_ROOK = 4
const W_QUEEN = 5
const W_KING = 6

# Black pieces
const B_PAWN = 7
const B_KNIGHT = 8
const B_BISHOP = 9
const B_ROOK = 10
const B_QUEEN = 11
const B_KING = 12

# Convenience: all piece types
const ALL_PIECES = W_PAWN:B_KING

#########################
# Board representation  #
#########################
"""
Information needed to undo a move
- `captured_piece`: The piece type that was captured, or 0 if none.
- `en_passant`: The previous en passant square.
- `castling_rights`: The previous castling rights.
- `halfmove_clock`: The previous halfmove clock.
- `moved_piece`: The piece type that was moved.
- `promotion`: The piece type if the move was a promotion, or 0 otherwise.
- `is_en_passant`: A boolean indicating if the move was an en passant capture.
"""
struct UndoInfo
    captured_piece::Int
    en_passant::Int
    castling_rights::Int
    halfmove_clock::Int
    moved_piece::Int
    promotion::Int
    is_en_passant::Bool
    prev_eval_score::Int
    prev_game_phase_value::Int
end

"""
A chess board representation using bitboards.
- `bitboards`: A dictionary mapping piece types to their corresponding bitboards.
- `side_to_move`: The side to move.
- `castling_rights`: A 4-bit integer representing castling rights (KQkq).
- `en_passant`: The square index (0-63) for en passant target, or -1 if none.
- `halfmove_clock`: The number of halfmoves since the last capture or pawn move (for the 50-move rule).
- `position_history`: A vector of position Zobrist hashes for detecting threefold repetition.
- `undo_stack`: A stack of `UndoInfo` structs for unmaking moves.
- `eval_score`: Cached evaluation score from White's point of view.
- `game_phase_value`: Cached phase numerator (sum of weights) for evaluation scaling.
"""
mutable struct Board
    bitboards::Dict{Int, UInt64} # piece type → bitboard
    side_to_move::Side
    castling_rights::UInt8      # four bits: KQkq
    en_passant::Int             # square index 0..63, or -1 if none
    halfmove_clock::Int          # for 50-move rule
    position_history::Vector{UInt64}  # for threefold repetition
    undo_stack::Vector{UndoInfo} # stack of UndoInfo for unmaking moves
    eval_score::Int           # cached evaluation from White’s POV
    game_phase_value::Int     # cached phase numerator (sum of weights)
end

function Base.:(==)(a::Board, b::Board)
    a.bitboards == b.bitboards &&
        a.side_to_move == b.side_to_move &&
        a.castling_rights == b.castling_rights &&
        a.en_passant == b.en_passant &&
        a.halfmove_clock == b.halfmove_clock &&
        a.position_history == b.position_history &&
        a.undo_stack == b.undo_stack &&
        a.eval_score == b.eval_score &&
        a.game_phase_value == b.game_phase_value
end

function position_equal(a::Board, b::Board)
    a.bitboards == b.bitboards &&
        a.side_to_move == b.side_to_move &&
        a.castling_rights == b.castling_rights &&
        a.en_passant == b.en_passant &&
        a.halfmove_clock == b.halfmove_clock &&
        a.eval_score == b.eval_score &&
        a.game_phase_value == b.game_phase_value
end

######################### # Square / bit helpers # ######################### 
"Map (file, rank) → square index (0..63). file=1→a, rank=1→1."
square_index(file::Int, rank::Int) = (rank - 1) * 8 + (file - 1)

"Map algebraic notation (e.g. 'e3') → square index (0..63)."
function square_index(sq::AbstractString)
    file_char, rank_char = sq[1], sq[2]   # e.g. "e3" → 'e', '3'
    file = Int(file_char) - Int('a') + 1  # 'a' → 1, 'b' → 2, ...
    rank = parse(Int, string(rank_char))  # '3' → 3
    return (rank - 1) * 8 + (file - 1)
end

"Set bit at square sq."
setbit(bb::UInt64, sq::Int) = bb | (UInt64(1) << sq)

"Clear bit at square sq."
clearbit(bb::UInt64, sq::Int) = bb & ~(UInt64(1) << sq)

"Check if bit at square sq is set."
testbit(bb::UInt64, sq::Int) = ((bb >> sq) & 0x1) == 1

######################### Zobrist hashing #########################

using Random

# Tables
const ZOBRIST_PIECES = Array{UInt64}(undef, 12, 64)
const ZOBRIST_CASTLING = Array{UInt64}(undef, 16)
const ZOBRIST_EP = Array{UInt64}(undef, 8)
const ZOBRIST_SIDE = Ref{UInt64}(0)

function init_zobrist!()
    rng = MersenneTwister(1405)

    # Side to move
    ZOBRIST_SIDE[] = rand(rng, UInt64)

    # Pieces 12 × 64
    for p in 1:12, sq in 1:64

        ZOBRIST_PIECES[p, sq] = rand(rng, UInt64)
    end

    # Castling rights 0..15
    for i in 0:15
        ZOBRIST_CASTLING[i + 1] = rand(rng, UInt64)
    end

    # En passant files a..h
    for f in 1:8
        ZOBRIST_EP[f] = rand(rng, UInt64)
    end
end

# Initialize tables
init_zobrist!()

function zobrist_hash(board::Board)
    h::UInt64 = 0

    # Pieces
    for p in ALL_PIECES
        bb = board.bitboards[p]
        while bb != 0
            sq = trailing_zeros(bb) # 0..63
            h ⊻= ZOBRIST_PIECES[p, sq + 1]
            bb &= bb - 1
        end
    end

    # Side to move
    if board.side_to_move == BLACK
        h ⊻= ZOBRIST_SIDE[]
    end

    # Castling rights
    h ⊻= ZOBRIST_CASTLING[Int(board.castling_rights) + 1]

    # En passant (file only)
    if board.en_passant != -1
        file = (board.en_passant % 8) + 1
        h ⊻= ZOBRIST_EP[file]
    end

    return h
end

#########################
# Initial position      #
#########################

function start_position()
    bitboards = Dict{Int, UInt64}()

    # Pawns
    bitboards[W_PAWN] = 0x000000000000FF00
    bitboards[B_PAWN] = 0x00FF000000000000

    # Knights
    bitboards[W_KNIGHT] = 0x0000000000000042
    bitboards[B_KNIGHT] = 0x4200000000000000

    # Bishops
    bitboards[W_BISHOP] = 0x0000000000000024
    bitboards[B_BISHOP] = 0x2400000000000000

    # Rooks
    bitboards[W_ROOK] = 0x0000000000000081
    bitboards[B_ROOK] = 0x8100000000000000

    # Queens
    bitboards[W_QUEEN] = 0x0000000000000008
    bitboards[B_QUEEN] = 0x0800000000000000

    # Kings
    bitboards[W_KING] = 0x0000000000000010
    bitboards[B_KING] = 0x1000000000000000

    # White to move, all castling rights, no en passant
    return Board(bitboards, WHITE, 0xF, -1, 0, UInt64[], UndoInfo[], 0, 24)
end
