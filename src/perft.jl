const MAX_MOVES = 256  # 256 is safely larger than max legal moves

function perft(board::Board, depth::Int)
    levels = depth + 1  # allocate one buffer for each level
    moves_stack = [Vector{Move}(undef, MAX_MOVES) for _ in 1:levels]
    pseudo_stack = [Vector{Move}(undef, MAX_MOVES) for _ in 1:levels]

    return _perft!(board, depth, moves_stack, pseudo_stack, 1)
end

"""
    perft(board::Board, depth::Int) -> Int

Compute the number of leaf nodes reachable from the given board position at the given depth.
"""
function _perft!(
        board::Board,
        depth::Int,
        moves_stack::Vector{Vector{Move}},
        pseudo_stack::Vector{Vector{Move}},
        level::Int
)
    if depth == 0
        return 1
    end

    nodes = 0
    moves = moves_stack[level]
    pseudo = pseudo_stack[level]
    empty!(pseudo)

    OrbisChessEngine.generate_legal_moves_fast!(board, moves, pseudo)

    @inbounds for i in eachindex(moves)
        move = moves[i]
        make_move!(board, move)
        nodes += _perft!(board, depth - 1, moves_stack, pseudo_stack, level + 1)
        undo_move!(board, move)
    end

    return nodes
end

# Mainly for debugging: print per-move counts at the top level
function perft_divide(board::Board, depth::Int)
    levels = depth + 1  # one buffer per level
    moves_stack = [Vector{Move}(undef, MAX_MOVES) for _ in 1:levels]
    pseudo_stack = [Vector{Move}(undef, MAX_MOVES) for _ in 1:levels]

    # Generate all root moves
    moves = moves_stack[1]
    pseudo = pseudo_stack[1]
    empty!(pseudo)

    OrbisChessEngine.generate_legal_moves_fast!(board, moves, pseudo)
    n = length(moves)

    println("Depth $depth perft divide: $(n) moves")

    total = 0

    for i in 1:n
        move = moves[i]
        make_move!(board, move)

        # recursive call using preallocated stacks
        nodes = _perft!(board, depth - 1, moves_stack, pseudo_stack, 2)

        undo_move!(board, move)
        total += nodes

        println(string(move), ": ", nodes)
    end

    println("Total: ", total)
    return total
end

using Base.Threads

# Helper: split moves into chunks for threads
function split_indices(nmoves, nthreads)
    chunk_sizes = fill(div(nmoves, nthreads), nthreads)
    for i in 1:rem(nmoves, nthreads)
        chunk_sizes[i] += 1
    end

    chunks = Vector{UnitRange{Int}}(undef, nthreads)
    start = 1
    for i in 1:nthreads
        stop = start + chunk_sizes[i] - 1
        chunks[i] = start:stop
        start = stop + 1
    end
    return chunks
end

"""
    perft_fast(board::Board, depth::Int) -> Int

Compute the number of leaf nodes reachable from the given board position at the given depth
using multiple threads.
"""
function perft_fast(board::Board, depth::Int)
    if depth == 0
        return 1
    end
    moves = Vector{Move}(undef, MAX_MOVES)
    pseudo = Vector{Move}(undef, MAX_MOVES)
    empty!(pseudo)

    OrbisChessEngine.generate_legal_moves_fast!(board, moves, pseudo)
    nmoves = length(moves)

    nthreads_ = Threads.nthreads()
    chunks = split_indices(nmoves, nthreads_)

    futures = Vector{Task}(undef, nthreads_)

    for t in 1:nthreads_
        range = chunks[t]

        futures[t] = Threads.@spawn begin
            # make a thread-local board copy
            local_board = deepcopy(board)

            # thread-local recursion stacks
            moves_stack = [Vector{Move}(undef, MAX_MOVES) for _ in 1:(depth+1)]
            pseudo_stack = [Vector{Move}(undef, MAX_MOVES) for _ in 1:(depth+1)]

            nodes = 0
            for i in range
                move = moves[i]
                make_move!(local_board, move)
                nodes += _perft!(local_board, depth-1, moves_stack, pseudo_stack, 2)
                undo_move!(local_board, move)
            end
            return nodes
        end
    end

    return sum(fetch.(futures))
end
