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
    undo_move!(board, m)

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

# Quiescence search: only searches captures 
const MAX_QUIESCENCE_PLY = 4

function quiescence(board::Board, α::Int, β::Int; ply::Int = 0)
    side_to_move = board.side_to_move
    static_eval = evaluate(board)  # evaluation if we stop here

    if side_to_move == WHITE
        # White wants to maximize score
        if static_eval >= β
            return β   # beta cutoff
        end
        if static_eval > α
            α = static_eval
        end
    else
        # Black wants to minimize score
        if static_eval <= α
            return α   # alpha cutoff
        end
        if static_eval < β
            β = static_eval
        end
    end

    # Prevent runaway recursion in capture sequences
    if ply >= MAX_QUIESCENCE_PLY
        return static_eval
    end

    best_score = static_eval
    for move in generate_captures(board)
        make_move!(board, move)
        score = quiescence(board, α, β; ply = ply+1)
        undo_move!(board, move)

        if side_to_move == WHITE
            if score > best_score
                best_score = score
            end
            if best_score > α
                α = best_score
            end
            if α >= β
                break  # beta cutoff
            end
        else
            if score < best_score
                best_score = score
            end
            if best_score < β
                β = best_score
            end
            if β <= α
                break  # alpha cutoff
            end
        end
    end

    return best_score
end

function is_endgame(board::Board)
    # Consider endgame when phase < 5
    return board.game_phase_value < 5
end

"""
    SearchResult

Result of a search operation.

- `score`: The evaluation score of the position (nothing if from book).
- `move`: The best move found (nothing if from book).
- `from_book`: Boolean indicating if the move was from the opening book.
"""
struct SearchResult
    score::Union{Nothing, Int}  # nothing if from book
    move::Union{Nothing, Move}
    from_book::Bool
end

# Alpha-beta search with quiescence at leaves
function _search(board::Board;
        depth::Int,
        ply::Int = 0,
        α::Int = -MATE_VALUE,
        β::Int = MATE_VALUE,
        opening_book::Union{Nothing, PolyglotBook} = KOMODO_OPENING_BOOK,
        stop_time::Int = typemax(Int))::SearchResult

    # Time check
    if (time_ns() ÷ 1_000_000) >= stop_time
        return SearchResult(nothing, nothing, false)
    end

    # Opening book
    if opening_book !== nothing && ply == 0
        book_mv = book_move(board, opening_book)
        if book_mv !== nothing
            return SearchResult(nothing, book_mv, true)
        end
    end

    hash_before = zobrist_hash(board)

    # TT lookup
    val, move, hit = tt_probe(hash_before, depth, α, β)
    if hit
        return SearchResult(val, move, false)
    end

    # Leaf node: use quiescence search
    if depth == 0
        return SearchResult(quiescence(board, α, β), nothing, false)
    end

    # Null move pruning
    R = 2  # reduction factor for null move pruning
    if depth > R + 1 && !is_endgame(board)
        make_null_move!(board)  # side passes
        result = _search(board; depth = depth - 1 - R, ply = ply + 1, α = -β, β = -β + 1,
            opening_book = nothing, stop_time = stop_time)
        unmake_null_move!(board)

        if board.side_to_move == WHITE && result.score >= β
            return SearchResult(result.score, nothing, false)  # beta cutoff
        elseif board.side_to_move == BLACK && result.score <= α
            return SearchResult(result.score, nothing, false)  # alpha cutoff
        end
    end

    moves = Vector{Move}(undef, 0)
    generate_legal_moves!(board, moves)
    moves = sort(moves; by = m -> -move_ordering_score(board, m, ply))

    if isempty(moves)
        val = if in_check(board, board.side_to_move)
            board.side_to_move == WHITE ? -MATE_VALUE + ply : MATE_VALUE - ply
        else
            0
        end
        return SearchResult(val, nothing, false)
    end

    best_score = board.side_to_move == WHITE ? -Inf : Inf
    best_move = nothing

    for (i, m) in enumerate(moves)
        if (time_ns() ÷ 1_000_000) >= stop_time
            val = best_score == -Inf || best_score == Inf ? 0 : best_score
            return SearchResult(val, best_move, false)
        end

        make_move!(board, m)
        result = _search(board; depth = depth - 1, ply = ply + 1, α = α, β = β,
            opening_book = opening_book, stop_time = stop_time)
        undo_move!(board, m)

        # Alpha-beta update
        if board.side_to_move == WHITE
            if result.score > best_score
                best_score = result.score
                best_move = m
                α = max(α, best_score)
                if best_score >= β
                    store_killer!(m, ply)
                    break
                end
            end
        else
            if result.score < best_score
                best_score = result.score
                best_move = m
                β = min(β, best_score)
                if best_score <= α
                    store_killer!(m, ply)
                    break
                end
            end
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

    return SearchResult(best_score, best_move, false)
end

function tt_probe_raw(hash::UInt64)
    idx = tt_index(hash)
    entry = TRANSPOSITION_TABLE[idx]
    if entry !== nothing && entry.key == hash
        return entry.value, entry.best_move, true
    else
        return nothing, nothing, false
    end
end

"Reconstruct the principal variation (PV) from the transposition table"
function extract_pv(board::Board, max_depth::Int)
    pv = Move[]
    temp_board = deepcopy(board)
    for d in 1:max_depth
        h = zobrist_hash(temp_board)
        val, move, hit = tt_probe_raw(h)
        if !hit || move === nothing
            break
        end
        push!(pv, move)
        make_move!(temp_board, move)
    end
    return pv
end

# Root-level iterative deepening search
function search_root(board::Board, max_depth::Int;
        stop_time::Int = typemax(Int),
        opening_book::Union{Nothing, PolyglotBook} = KOMODO_OPENING_BOOK,
        verbose::Bool = false)::SearchResult
    best_result = SearchResult(0.0, nothing, false)

    # Opening book probe
    if opening_book !== nothing
        book_mv = book_move(board, opening_book)
        if book_mv !== nothing
            if verbose
                println("Book move found: $book_mv")
            end
            return SearchResult(nothing, book_mv, true)
        end
    end

    for depth in 1:max_depth
        result = _search(board; depth = depth, ply = 0, α = -MATE_VALUE, β = MATE_VALUE,
            stop_time = stop_time, opening_book = nothing)
        if result.move !== nothing
            best_result = result
        end

        if verbose
            pv = extract_pv(board, depth)
            pv_str = join(string.(pv), " ")
            println("Depth $depth | Score: $(best_result.score) | PV: $pv_str")
        end

        if (time_ns() ÷ 1_000_000) >= stop_time
            break
        end
    end

    return best_result
end

"""
    search(
        board::Board, 
        depth::Int;
        ply::Int = 0,
        α::Int = (-MATE_VALUE),
        β::Int = MATE_VALUE,
        opening_book::Union{Nothing,PolyglotBook} = KOMODO_OPENING_BOOK,
        verbose::Bool = false,
        time_budget::Int = typemax(Int)
    )

Search for the best move using minimax with alpha-beta pruning, quiescence search,
null move pruning, and transposition tables.

Arguments:
- `board`: current board position
- `depth`: search depth
- `opening_book`: if provided, uses a opening book. Default is `KOMODO_OPENING_BOOK` 
taken from https://github.com/gmcheems-org/free-opening-books. Set to `nothing` to disable. 
- `verbose`: if true, prints a single-line progress indicator (only at root)
- `time_budget`: time in milliseconds to stop the search (if depth not reached)
Returns:
- `(best_score, best_move)`
"""
function search(
        board::Board;
        depth::Int,
        opening_book::Union{Nothing, PolyglotBook} = KOMODO_OPENING_BOOK,
        verbose::Bool = false,
        time_budget::Int = typemax(Int)
)::SearchResult
    tb = min(time_budget, 1_000_000_000)  # cap to 1e9 ms ~ 11 days
    stop_time = Int((time_ns() ÷ 1_000_000) + tb)
    return search_root(board, depth; stop_time = stop_time, opening_book = opening_book,
        verbose = verbose)
end
