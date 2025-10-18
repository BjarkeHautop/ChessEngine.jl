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

    # Generate legal moves and get the number of moves
    n_moves = generate_legal_moves!(board, moves, pseudo)

    @inbounds for i in 1:n_moves
        move = moves[i]
        make_move!(board, move)
        nodes += _perft!(board, depth - 1, moves_stack, pseudo_stack, level + 1)
        undo_move!(board, move)
    end

    return nodes
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
using multiple threads at the root.
"""
function perft_fast(board::Board, depth::Int)
    if depth == 0
        return 1
    end

    # Preallocate moves/pseudo stacks for the root
    moves_stack = [Vector{Move}(undef, MAX_MOVES) for _ in 1:(depth + 1)]
    pseudo_stack = [Vector{Move}(undef, MAX_MOVES) for _ in 1:(depth + 1)]

    # Generate legal moves at root
    root_moves = moves_stack[1]
    root_pseudo = pseudo_stack[1]
    n_moves = generate_legal_moves!(board, root_moves, root_pseudo)

    # Split moves among threads
    nthreads_ = min(n_moves, Threads.nthreads())  # don't spawn more threads than moves
    chunks = split_indices(n_moves, nthreads_)

    # Spawn tasks for each thread
    futures = Vector{Task}(undef, nthreads_)
    for t in 1:nthreads_
        range = chunks[t]
        futures[t] = Threads.@spawn begin
            local_board = deepcopy(board)  # thread-local board
            local_moves_stack = [Vector{Move}(undef, MAX_MOVES) for _ in 1:(depth + 1)]
            local_pseudo_stack = [Vector{Move}(undef, MAX_MOVES) for _ in 1:(depth + 1)]

            nodes = 0
            for i in range
                move = root_moves[i]
                make_move!(local_board, move)
                nodes += _perft!(
                    local_board, depth-1, local_moves_stack, local_pseudo_stack, 2)
                undo_move!(local_board, move)
            end
            return nodes
        end
    end

    return sum(fetch.(futures))
end

# Using magic bitboard for bishop moves in perft

function perft_bishop_magic(board::Board, depth::Int)
    levels = depth + 1  # allocate one buffer for each level
    moves_stack = [Vector{Move}(undef, MAX_MOVES) for _ in 1:levels]
    pseudo_stack = [Vector{Move}(undef, MAX_MOVES) for _ in 1:levels]

    return _perft_bishop_magic!(board, depth, moves_stack, pseudo_stack, 1)
end

function _perft_bishop_magic!(
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

    # Generate legal moves and get the number of moves
    n_moves = generate_legal_moves_bishop_magic!(board, moves, pseudo)

    @inbounds for i in 1:n_moves
        move = moves[i]
        make_move!(board, move)
        nodes += _perft_bishop_magic!(
            board, depth - 1, moves_stack, pseudo_stack, level + 1)
        undo_move!(board, move)
    end

    return nodes
end

function perft_new(board::Board, depth::Int)
    levels = depth + 1  # allocate one buffer for each level
    moves_stack = [Vector{Move}(undef, MAX_MOVES) for _ in 1:levels]
    pseudo_stack = [Vector{Move}(undef, MAX_MOVES) for _ in 1:levels]

    return _perft_new!(board, depth, moves_stack, pseudo_stack, 1)
end

"""
    perft(board::Board, depth::Int) -> Int

Compute the number of leaf nodes reachable from the given board position at the given depth.
"""
function _perft_new!(
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

    # Generate legal moves and get the number of moves
    n_moves = generate_legal_moves_fast!(board, moves, pseudo)

    @inbounds for i in 1:n_moves
        move = moves[i]
        make_move!(board, move)
        nodes += _perft_new!(board, depth - 1, moves_stack, pseudo_stack, level + 1)
        undo_move!(board, move)
    end

    return nodes
end
