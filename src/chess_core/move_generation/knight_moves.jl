# Internal helper for knight moves
function _generate_knight_moves_internal(board::Board, push_fn)
    knights, friendly_pieces,
    enemy_pieces = board.side_to_move == WHITE ?
                   (board.bitboards[Piece.W_KNIGHT],
        Piece.W_PAWN:Piece.W_KING, Piece.B_PAWN:Piece.B_KING) :
                   (board.bitboards[Piece.B_KNIGHT],
        Piece.B_PAWN:Piece.B_KING, Piece.W_PAWN:Piece.W_KING)

    # build bitboard of all friendly pieces
    occupied_friendly = zero(UInt64)
    for p in friendly_pieces
        occupied_friendly |= board.bitboards[p]
    end

    # Knight move offsets
    deltas = [-17, -15, -10, -6, 6, 10, 15, 17]

    for sq in 0:63
        if !testbit(knights, sq)
            continue
        end

        f, r = file_rank(sq)
        for d in deltas
            to_sq = sq + d
            if !on_board(to_sq)
                continue
            end

            tf, tr = file_rank(to_sq)
            df = abs(tf - f)
            dr = abs(tr - r)

            # Only valid L-shaped moves
            if (df == 2 && dr == 1) || (df == 1 && dr == 2)
                if !testbit(occupied_friendly, to_sq)
                    # capture check
                    capture = 0
                    for p in enemy_pieces
                        if testbit(board.bitboards[p], to_sq)
                            capture = p
                            break
                        end
                    end
                    push_fn(sq, to_sq; capture = capture)
                end
            end
        end
    end
end

# Returns a vector of moves
function generate_knight_moves(board::Board)
    moves = Move[]
    _generate_knight_moves_internal(board, (
        sq, to_sq; kwargs...) -> push!(moves, Move(sq, to_sq; kwargs...)))
    return moves
end

# In-place version
function generate_knight_moves_old!(board::Board, moves::Vector{Move})
    len_before = length(moves)
    _generate_knight_moves_internal(board, (
        sq, to_sq; kwargs...) -> push!(moves, Move(sq, to_sq; kwargs...)))
    return length(moves) - len_before
end

# Preallocate a 64-element constant array
const knight_attack_masks = Vector{UInt64}(undef, 64)

function init_knight_masks!()
    for sq in 0:63
        mask = zero(UInt64)
        f, r = sq % 8, sq ÷ 8
        for df in (-2, -1, 1, 2)
            for dr in (-2, -1, 1, 2)
                if abs(df) != abs(dr)  # L-shape
                    tf, tr = f + df, r + dr
                    if 0 <= tf < 8 && 0 <= tr < 8
                        mask |= UInt64(1) << (tr * 8 + tf)
                    end
                end
            end
        end
        knight_attack_masks[sq + 1] = mask  
    end
end

# Initialize once at startup
init_knight_masks!()

function generate_knight_moves!(board::Board, moves::Vector{Move})
    if board.side_to_move == WHITE
        knights = board.bitboards[Piece.W_KNIGHT]
        friendly_mask = board.bitboards[Piece.W_PAWN] | board.bitboards[Piece.W_KNIGHT] |
                        board.bitboards[Piece.W_BISHOP] | board.bitboards[Piece.W_ROOK] |
                        board.bitboards[Piece.W_QUEEN] | board.bitboards[Piece.W_KING]
        enemy_mask = board.bitboards[Piece.B_PAWN] | board.bitboards[Piece.B_KNIGHT] |
                     board.bitboards[Piece.B_BISHOP] | board.bitboards[Piece.B_ROOK] |
                     board.bitboards[Piece.B_QUEEN] | board.bitboards[Piece.B_KING]
        enemy_range = Piece.B_PAWN:Piece.B_KING
    else
        knights = board.bitboards[Piece.B_KNIGHT]
        friendly_mask = board.bitboards[Piece.B_PAWN] | board.bitboards[Piece.B_KNIGHT] |
                        board.bitboards[Piece.B_BISHOP] | board.bitboards[Piece.B_ROOK] |
                        board.bitboards[Piece.B_QUEEN] | board.bitboards[Piece.B_KING]
        enemy_mask = board.bitboards[Piece.W_PAWN] | board.bitboards[Piece.W_KNIGHT] |
                     board.bitboards[Piece.W_BISHOP] | board.bitboards[Piece.W_ROOK] |
                     board.bitboards[Piece.W_QUEEN] | board.bitboards[Piece.W_KING]
        enemy_range = Piece.W_PAWN:Piece.W_KING
    end

    bb = knights
    while bb != 0
        sq = trailing_zeros(bb)
        bb &= bb - 1

        attacks = knight_attack_masks[sq + 1] & ~friendly_mask
        attack_bb = attacks
        while attack_bb != 0
            to_sq = trailing_zeros(attack_bb)
            attack_bb &= attack_bb - 1

            capture = 0
            if enemy_mask & (UInt64(1) << to_sq) != 0
                for p in enemy_range
                    if board.bitboards[p] & (UInt64(1) << to_sq) != 0
                        capture = p
                        break
                    end
                end
            end

            push!(moves, Move(sq, to_sq; capture=capture))
        end
    end
end
