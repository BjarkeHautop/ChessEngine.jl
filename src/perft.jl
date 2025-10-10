"""
    perft(board::Board, depth::Int) -> Int

Performance test function: counts the number of leaf nodes reachable
from the given board position up to `depth`.
"""
function perft(board::Board, depth::Int)
    if depth == 0
        return 1
    end

    nodes = 0
    for move in generate_legal_moves(board)
        make_move!(board, move)
        nodes += perft(board, depth - 1)
        undo_move!(board, move)
    end

    return nodes
end

const MAX_MOVES = 256  # 256 is safely larger than max legal moves

"""
    perft_fast(board::Board, depth::Int) -> Int

Fast perft function using a preallocated moves buffer
to avoid repeated allocations. Ideal for benchmarking.
"""
function perft_fast(board::Board, depth::Int)
    moves = Vector{Move}(undef, MAX_MOVES)  # 256 is safely larger than max legal moves
    return _perft_fast!(board, depth, moves)
end


# internal recursive function
function _perft_fast!(board::Board, depth::Int, moves::Vector{Move})
    if depth == 0
        return 1
    end

    nodes = 0
    generate_legal_moves!(board, moves)
    n = length(moves)

    # Preallocate a new buffer for recursion
    moves_child = Vector{Move}(undef, MAX_MOVES)

    @inbounds for i in 1:n
        move = moves[i]
        make_move!(board, move)
        nodes += _perft_fast!(board, depth - 1, moves_child)
        undo_move!(board, move)
    end

    return nodes
end

function perft_superfast(board::Board, depth::Int)
    levels = depth + 1  # allocate one buffer for each level (safe)
    moves_stack  = [Vector{Move}(undef, MAX_MOVES) for _ in 1:levels]
    pseudo_stack  = [Vector{Move}(undef, MAX_MOVES) for _ in 1:levels]

    return _perft_superfast!(board, depth, moves_stack, pseudo_stack, 1)
end

function _perft_superfast!(
        board::Board,
        depth::Int,
        moves_stack::Vector{Vector{Move}},
        pseudo_stack::Vector{Vector{Move}},
        level::Int,
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
        nodes += _perft_superfast!(board, depth - 1, moves_stack, pseudo_stack, level + 1)
        undo_move!(board, move)
    end

    return nodes
end

# Mainly for debugging: print per-move counts at the top level
function perft_divide(board::Board, depth::Int)
    moves = Vector{Move}(undef, MAX_MOVES)
    generate_legal_moves!(board, moves)
    n = length(moves)
    println("Depth $depth perft divide: $(n) moves")

    total = 0
    moves_child = Vector{Move}(undef, MAX_MOVES)

    for i in 1:n
        move = moves[i]
        make_move!(board, move)
        nodes = _perft_fast!(board, depth - 1, moves_child)
        undo_move!(board, move)
        total += nodes
        println(string(move), ": ", nodes)
    end

    println("Total: ", total)
    return total
end