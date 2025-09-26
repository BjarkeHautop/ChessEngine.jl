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

"""
    perft_fast(board::Board, depth::Int) -> Int

Fast perft function using a preallocated moves buffer
to avoid repeated allocations. Ideal for benchmarking.
"""
function perft_fast(board::Board, depth::Int)
    moves = Vector{Move}(undef, 256)  # 256 is safely larger than max legal moves
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
    moves_child = Vector{Move}(undef, 256)

    for i in 1:n
        move = moves[i]
        make_move!(board, move)
        nodes += _perft_fast!(board, depth - 1, moves_child)
        undo_move!(board, move)
    end

    return nodes
end
