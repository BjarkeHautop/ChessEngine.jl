# Piece values for move ordering
const PIECE_VALUES = Dict(
    Piece.W_PAWN => 100,
    Piece.B_PAWN => -100,
    Piece.W_KNIGHT => 300,
    Piece.B_KNIGHT => -300,
    Piece.W_BISHOP => 300,
    Piece.B_BISHOP => -300,
    Piece.W_ROOK => 500,
    Piece.B_ROOK => -500,
    Piece.W_QUEEN => 1000,
    Piece.B_QUEEN => -1000,
    Piece.W_KING => 0,
    Piece.B_KING => 0
)

# material weight used for phase calculation
function phase_weight(p)
    (p == Piece.W_QUEEN || p == Piece.B_QUEEN) ? 4 :
    (p == Piece.W_ROOK || p == Piece.B_ROOK) ? 2 :
    (p == Piece.W_BISHOP||p == Piece.B_BISHOP ||
     p == Piece.W_KNIGHT||p == Piece.B_KNIGHT) ? 1 : 0
end

# convert Board's phase counter into float
"""
Compute game phase (0 = endgame, 1 = opening). 
A simple heuristic: count non-pawn, non-king material. 
"""
function game_phase(board::Board)
    maxphase = 24
    return clamp(board.game_phase_value / maxphase, 0.0, 1.0)
end

"""
Evaluate a position from White’s perspective using piece-square tables.
"""
function evaluate(board::Board)
    score = 0
    phase = game_phase(board)
    for (p, bb) in enumerate(board.bitboards)
        while bb != 0
            square = trailing_zeros(bb)  # index of least significant 1-bit (0..63)
            score += piece_square_value(p, square, phase)
            bb &= bb - 1  # clear that bit
        end
    end
    return score
end

"""
    compute_eval_and_phase(board::Board) -> (Int, Int)

Compute the evaluation score (from White's perspective) and the game phase value
from scratch for a given board.
"""
function compute_eval_and_phase(board::Board)
    eval_score = 0
    game_phase_value = 0

    for (piece, bb) in enumerate(board.bitboards)
        while bb != 0
            sq = trailing_zeros(bb)
            bb &= bb - 1

            game_phase_value += phase_weight(piece)
        end
    end

    # Convert to float 0..1 for piece-square interpolation
    phase = clamp(game_phase_value / 24, 0.0, 1.0)

    # Now compute evaluation using that phase
    for (piece, bb) in enumerate(board.bitboards)
        tmp_bb = bb
        while tmp_bb != 0
            sq = trailing_zeros(tmp_bb)
            tmp_bb &= tmp_bb - 1

            eval_score += piece_square_value(piece, sq, phase)
        end
    end

    return eval_score, game_phase_value
end
