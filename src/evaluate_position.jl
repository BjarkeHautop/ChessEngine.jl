# Piece values for move ordering
const PIECE_VALUES = Dict(
    W_PAWN => 100,
    B_PAWN => -100,
    W_KNIGHT => 300,
    B_KNIGHT => -300,
    W_BISHOP => 300,
    B_BISHOP => -300,
    W_ROOK => 500,
    B_ROOK => -500,
    W_QUEEN => 1000,
    B_QUEEN => -1000,
    W_KING => 0,
    B_KING => 0
)

function init_evaluation!(board::Board)
    score = 0
    phase = 0
    for (p, bb) in board.bitboards
        while bb != 0
            sq = trailing_zeros(bb)
            score += piece_square_value(p, sq, 1.0)  # phase will be applied later
            if p == W_QUEEN || p == B_QUEEN
                phase += 4
            elseif p == W_ROOK || p == B_ROOK
                phase += 2
            elseif p == W_BISHOP || p == B_BISHOP || p == W_KNIGHT || p == B_KNIGHT
                phase += 1
            end
            bb &= bb - 1
        end
    end
    board.eval_score = score
    board.game_phase_value = phase
end

# material weight used for phase calculation
function phase_weight(p)
    (p == W_QUEEN || p == B_QUEEN) ? 4 :
    (p == W_ROOK || p == B_ROOK) ? 2 :
    (p == W_BISHOP||p == B_BISHOP ||
     p == W_KNIGHT||p == B_KNIGHT) ? 1 : 0
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
    for (p, bb) in board.bitboards
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

    for (piece, bb) in board.bitboards
        while bb != 0
            sq = trailing_zeros(bb)
            bb &= bb - 1

            game_phase_value += phase_weight(piece)
        end
    end

    # Convert to float 0..1 for piece-square interpolation
    phase = clamp(game_phase_value / 24, 0.0, 1.0)

    # Now compute evaluation using that phase
    for (piece, bb) in board.bitboards
        tmp_bb = bb
        while tmp_bb != 0
            sq = trailing_zeros(tmp_bb)
            tmp_bb &= tmp_bb - 1

            eval_score += piece_square_value(piece, sq, phase)
        end
    end

    return eval_score, game_phase_value
end
