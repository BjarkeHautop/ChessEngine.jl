# Internal shared logic for filtering pseudo-legal moves
function _filter_legal_moves!(board::Board, pseudo::Vector{Move}, start::Int,
        stop::Int, moves::Vector{Move}, n_moves::Int)
    side = board.side_to_move
    opp = opposite(side)
    @inbounds for i in start:stop
        m = pseudo[i]
        # Castling legality check
        if m.castling != 0
            if in_check(board, side)
                continue
            end

            # Castling path squares
            path = if side == WHITE
                m.castling == 1 ? (5, 6) : (3, 2)
            else
                m.castling == 1 ? (61, 62) : (59, 58)
            end

            illegal = false
            for sq in path
                if square_attacked(board, sq, opp)
                    illegal = true
                    break
                end
            end
            if illegal
                continue
            end
        end

        # Make move inplace and check legality
        make_move!(board, m)
        if in_check(board, side)
            undo_move!(board, m)
            continue
        end
        undo_move!(board, m)

        # Write move directly into preallocated array
        n_moves += 1
        moves[n_moves] = m
    end

    return n_moves
end

# Public API
function generate_legal_moves!(board::Board, moves::Vector{Move}, pseudo::Vector{Move})
    pseudo_len = 1
    pseudo_len = generate_pawn_moves!(board, pseudo, pseudo_len)
    pseudo_len = generate_knight_moves!(board, pseudo, pseudo_len)
    pseudo_len = generate_bishop_moves!(board, pseudo, pseudo_len)
    pseudo_len = generate_rook_moves!(board, pseudo, pseudo_len)
    pseudo_len = generate_queen_moves!(board, pseudo, pseudo_len)
    pseudo_len = generate_king_moves!(board, pseudo, pseudo_len)

    n_moves = 0
    # pseudo_len is one past the end
    n_moves = _filter_legal_moves!(board, pseudo, 1, pseudo_len-1, moves, n_moves)
    return n_moves
end

function generate_legal_moves(board::Board)
    moves = Vector{Move}(undef, MAX_MOVES)  # Preallocate maximum possible moves
    pseudo = Vector{Move}(undef, MAX_MOVES) # Preallocate maximum possible moves
    n_moves = generate_legal_moves!(board, moves, pseudo)
    return moves[1:n_moves]  # Return only the filled portion
end

function generate_legal_moves_bishop_magic!(
        board::Board,
        moves::Vector{Move},
        pseudo::Vector{Move}
)
    pseudo_len = 1

    pseudo_len = generate_pawn_moves!(board, pseudo, pseudo_len)
    pseudo_len = generate_knight_moves!(board, pseudo, pseudo_len)

    # Use magic bitboards for bishops
    pseudo_len = generate_bishop_moves_magic!(board, pseudo, pseudo_len)

    pseudo_len = generate_rook_moves!(board, pseudo, pseudo_len)
    pseudo_len = generate_queen_moves!(board, pseudo, pseudo_len)
    pseudo_len = generate_king_moves!(board, pseudo, pseudo_len)

    n_moves = 0
    # pseudo_len is one past the end
    n_moves = _filter_legal_moves!(board, pseudo, 1, pseudo_len - 1, moves, n_moves)

    return n_moves
end

const ROOK_DIRECTIONS = [(1, 0), (-1, 0), (0, 1), (0, -1)]
const SLIDING_DIRECTIONS = vcat(ROOK_DIRECTIONS, BISHOP_DIRECTIONS)
"""
    ray_between(board, king_sq::Int, from_sq::Int) -> Bool

Returns true if moving a piece from `from_sq` could open a sliding attack (rook, bishop, queen)
towards the king at `king_sq`.
"""
function ray_between(occ, king_sq, from_sq)
    @inbounds for dir in SLIDING_DIRECTIONS
        sq = king_sq
        while true
            sq = next_square(sq, dir)
            sq === nothing && break
            if sq == from_sq
                return true
            elseif ((occ >> sq) & 0x1) != 0
                break
            end
        end
    end
    return false
end

"""
    next_square(sq::Int, dir::Tuple{Int,Int}) -> Union{Int,Nothing}

Returns the next square index in direction `dir = (df, dr)` from `sq`.
Returns `nothing` if it goes off-board.
"""
function next_square(sq::Int, dir::Tuple{Int, Int})
    f, r = file_rank(sq)  # current file/rank (1..8)
    nf, nr = f + dir[1], r + dir[2]

    # check bounds
    if 1 <= nf <= 8 && 1 <= nr <= 8
        return square_index(nf, nr)
    else
        return nothing
    end
end

"""
    occupancy(board::Board) -> UInt64

Returns a bitboard of all occupied squares.
"""
@inline function occupancy(board::Board)
    occ = UInt64(0)
    for bb in board.bitboards
        occ |= bb
    end
    return occ
end

"""
    _filter_legal_moves_fast!(board, pseudo, start, stop, moves, n_moves)

Filters pseudo-legal moves into legal moves, avoiding full make/undo
for moves that clearly cannot expose the king.
"""
function _filter_legal_moves_fast!(board::Board, pseudo::Vector{Move},
        start::Int, stop::Int, moves::Vector{Move}, n_moves::Int)
    side = board.side_to_move
    opp = opposite(side)
    king_sq = king_square(board, side)
    occ = occupancy(board)
    in_check_now = in_check(board, side)

    @inbounds for i in start:stop
        m = pseudo[i]

        # --- Castling check ---
        if m.castling != 0
            # path squares for castling
            path = if side == WHITE
                m.castling == 1 ? (5, 6) : (3, 2)
            else
                m.castling == 1 ? (61, 62) : (59, 58)
            end
            if in_check(board, side) || any(sq -> square_attacked(board, sq, opp), path)
                continue
            end
        end

        # --- Lightweight legality check ---
        legal = false

        # quiet move that doesn't move the king and doesn't expose king along a ray
        if !in_check_now && !ray_between(occ, king_sq, m.from) && m.from != king_sq
            legal = true
        else
            # potentially dangerous move → full make/undo
            make_move!(board, m)
            legal = !in_check(board, side)
            undo_move!(board, m)
        end

        # --- Append to legal moves ---
        if legal
            n_moves += 1
            moves[n_moves] = m
        end
    end

    return n_moves
end

function generate_legal_moves_fast!(board::Board, moves::Vector{Move}, pseudo::Vector{Move})
    pseudo_len = 1
    pseudo_len = generate_pawn_moves!(board, pseudo, pseudo_len)
    pseudo_len = generate_knight_moves!(board, pseudo, pseudo_len)
    pseudo_len = generate_bishop_moves!(board, pseudo, pseudo_len)
    pseudo_len = generate_rook_moves!(board, pseudo, pseudo_len)
    pseudo_len = generate_queen_moves!(board, pseudo, pseudo_len)
    pseudo_len = generate_king_moves!(board, pseudo, pseudo_len)

    n_moves = 0
    # pseudo_len is one past the end
    n_moves = _filter_legal_moves_fast!(board, pseudo, 1, pseudo_len-1, moves, n_moves)
    return n_moves
end
