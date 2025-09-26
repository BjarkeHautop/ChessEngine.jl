"""
    perft(board::Board, depth::Int) -> Int

Performance test function: counts the number of leaf nodes reachable
from the given board position up to `depth`.
"""
function perft(board::Board, depth::Int, moves::Vector{Move})
    if depth == 0
        return 1
    end
    nodes = 0
    n = generate_moves!(board, moves)  # fills `moves[1:n]`
    @inbounds for i = 1:n
        move = moves[i]
        make_move!(board, move)
        nodes += perft(board, depth - 1, moves)
        undo_move!(board)
    end
    return nodes
end


"""
    perft_fast(board::Board, depth::Int) -> Int

Fast perft function using a preallocated moves buffer
to avoid repeated allocations. Ideal for benchmarking.
"""
function perft_fast(board::Board, depth::Int)
    # preallocate a moves buffer large enough for any node
    moves = Vector{Move}(undef, 256)  # 256 is safely larger than max legal moves
    return _perft_fast!(board, depth, moves)
end

# internal recursive function
function _perft_fast!(board::Board, depth::Int, moves::Vector{Move})
    if depth == 0
        return 1
    end

    nodes = 0
    n = generate_legal_moves!(board, moves)  # fills moves[1:n]

    @inbounds for i = 1:n
        move = moves[i]
        make_move!(board, move)
        nodes += _perft_fast!(board, depth - 1, moves)
        undo_move!(board)
    end

    return nodes
end
