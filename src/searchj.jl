const MATE_VALUE = 30_000
const MATE_THRESHOLD = 29_000  # threshold to consider a position as mate

const MAX_PLY = 128  # safe upper bound for typical search depth
const KILLERS = [Vector{Union{Move, Nothing}}(undef, 2) for _ in 1:MAX_PLY]

"""
Store a killer move for the given ply.
Only quiet moves (non-captures) are stored.
- m: the move to store
- ply: the current ply
"""
function store_killer!(m::Move, ply::Int)
    if m.capture == 0  # only quiet moves
        ply_idx = ply + 1
        if KILLERS[ply_idx][1] != m
            KILLERS[ply_idx][2] = KILLERS[ply_idx][1]
            KILLERS[ply_idx][1] = m
        end
    end
end

"""
Heuristic to score moves for ordering:
- Promotions are prioritized highest.
- Captures are prioritized higher.
- Moves giving check are prioritized.
- Quiet moves get a lower score.
"""
function move_ordering_score(board::Board, m::Move, ply::Int)
    score = 0
    capture_multiplier = 10
    in_check_bonus = 5000
    promotion_bonus = 8000
    killer_bonus = 4000

    # Killer move bonus (only quiet moves)
    if m.capture == 0 && (KILLERS[ply + 1][1] == m || KILLERS[ply + 1][2] == m)
        score += killer_bonus
    end

    # Captures: MVV-LVA
    if m.capture != 0
        attacker_piece = piece_at(board, m.from)
        capture_val = abs(PIECE_VALUES[m.capture])
        attacker_val = abs(PIECE_VALUES[attacker_piece])
        score += capture_val * capture_multiplier - attacker_val
    end

    # Bonus for checks
    make_move!(board, m)
    if in_check(board, board.side_to_move == WHITE ? BLACK : WHITE)
        score += in_check_bonus
    end

    # Bonus for promotions
    if m.promotion != 0
        score += abs(PIECE_VALUES[m.promotion]) + promotion_bonus
    end
    unmake_move!(board, m)

    return score
end

# Types of stored nodes
@enum NodeType EXACT LOWERBOUND UPPERBOUND

"""
Transposition table entry.
- key: Zobrist hash of the position (for collision checking)
- value: evaluation score
- depth: search depth at which this value was computed
- node_type: type of node (EXACT, LOWERBOUND, UPPERBOUND)
- best_move: best move found from this position
"""
struct TTEntry
    key::UInt64
    value::Int
    depth::Int
    node_type::NodeType
    best_move::Union{Move, Nothing}
end

const TT_SIZE = 1 << 20  # ~1M entries, adjust to your memory budget
const TRANSPOSITION_TABLE = Vector{Union{TTEntry, Nothing}}(undef, TT_SIZE)

"""
Get index in transposition table from hash.
"""
@inline function tt_index(hash::UInt64)
    return Int(hash & (TT_SIZE - 1)) + 1  # mask for power-of-2 table
end

"""
Look up a position in the transposition table.
- hash: Zobrist hash of the position
- depth: current search depth
- α: alpha value
- β: beta value

Returns a tuple (value, best_move, hit) where hit is true if a valid entry was found.
"""
function tt_probe(hash::UInt64, depth::Int, α::Int, β::Int)
    idx = tt_index(hash)
    entry = TRANSPOSITION_TABLE[idx]
    if entry !== nothing && entry.key == hash && entry.depth >= depth
        if entry.node_type == EXACT
            return entry.value, entry.best_move, true
        elseif entry.node_type == LOWERBOUND && entry.value > α
            α = entry.value
        elseif entry.node_type == UPPERBOUND && entry.value < β
            β = entry.value
        end
        if α >= β
            return entry.value, entry.best_move, true
        end
    end
    return 0, nothing, false
end

"""
Store an entry in the transposition table.
"""
function tt_store(hash::UInt64, value::Int, depth::Int, node_type::NodeType, best_move)
    idx = tt_index(hash)
    entry = TRANSPOSITION_TABLE[idx]
    if entry === nothing || depth >= entry.depth
        TRANSPOSITION_TABLE[idx] = TTEntry(hash, value, depth, node_type, best_move)
    end
end

"""
Search for the best move using minimax with alpha-beta pruning.

Arguments:
- `board`: current board position
- `depth`: search depth
- `ply`: current ply (for mate distance adjustment)
- `α`: alpha value
- `β`: beta value
- `opening_book`: if true, use opening book moves if available
- `verbose`: if true, prints a single-line progress indicator (only at root)
- `stop_time`: time in milliseconds to stop the search

Returns:
- `(best_score, best_move)`
"""
function search(
        board::Board,
        depth::Int;
        ply::Int = 0,
        α::Int = (-MATE_VALUE),
        β::Int = MATE_VALUE,
        opening_book::Bool = true,
        verbose::Bool = false,
        stop_time::Int = typemax(Int)
)
    # stop check
    if (time_ns() ÷ 1_000_000) >= stop_time
        return 0, nothing
    end

    if opening_book && ply == 0
        book_mv = book_move(board, OPENING_BOOK)
        if book_mv !== nothing
            return 0, book_mv  # score is irrelevant for book moves
        end
    end
    hash_before = zobrist_hash(board)   # hash at start of this node

    # TT lookup
    val, move, hit = tt_probe(hash_before, depth, α, β)
    if hit
        return val, move
    end

    if depth == 0
        return evaluate(board), nothing
    end

    moves = generate_legal_moves(board)
    moves = sort(moves; by = m -> -move_ordering_score(board, m, ply))

    if isempty(moves)
        if in_check(board, board.side_to_move)
            return board.side_to_move == WHITE ? -MATE_VALUE + ply : MATE_VALUE - ply,
            nothing
        else
            return 0, nothing
        end
    end

    best_score = board.side_to_move == WHITE ? -Inf : Inf
    best_move = nothing

    total = length(moves)
    done = 0

    for m in moves
        if (time_ns() ÷ 1_000_000) >= stop_time
            return best_score == -Inf || best_score == Inf ? 0 : best_score, best_move
        end

        make_move!(board, m)
        score, _ = search(board, depth-1; ply = ply+1, α = α, β = β, verbose = verbose)
        unmake_move!(board, m)

        # Alpha-beta update
        if board.side_to_move == WHITE
            if score > best_score
                best_score = score
                best_move = m
                α = max(α, best_score)
                if best_score >= β
                    store_killer!(m, ply)
                    break
                end
            end
        else
            if score < best_score
                best_score = score
                best_move = m
                β = min(β, best_score)
                if best_score <= α
                    store_killer!(m, ply)
                    break
                end
            end
        end

        done += 1
        if verbose && ply == 0
            pct = round(Int, 100 * done / total)
            print("\rSearching depth $depth: $done/$total moves ($pct%)")
            flush(stdout)
        end
    end

    # TT store
    node_type = EXACT
    if best_score <= α
        node_type = UPPERBOUND
    elseif best_score >= β
        node_type = LOWERBOUND
    end
    tt_store(hash_before, best_score, depth, node_type, best_move)

    if verbose && ply == 0
        println()  # finish the line after root search completes
    end

    return best_score, best_move
end
