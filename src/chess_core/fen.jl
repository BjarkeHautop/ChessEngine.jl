function board_from_fen(fen::String)
    parts = split(fen)
    @assert length(parts) >= 4 "FEN must have at least 4 fields"

    # Piece placement
    rows = split(parts[1], '/')
    @assert length(rows) == 8 "FEN must have 8 ranks"

    # Initialize empty bitboards
    bitboards = Dict{Int, UInt64}()
    for piece in 1:12
        bitboards[piece] = UInt64(0)
    end

    # Map FEN chars to piece types
    PIECE_MAP = Dict(
        'P' => W_PAWN, 'N' => W_KNIGHT, 'B' => W_BISHOP,
        'R' => W_ROOK, 'Q' => W_QUEEN, 'K' => W_KING,
        'p' => B_PAWN, 'n' => B_KNIGHT, 'b' => B_BISHOP,
        'r' => B_ROOK, 'q' => B_QUEEN, 'k' => B_KING
    )

    for (rank_idx, row) in enumerate(rows)
        file = 0
        for c in row
            if isdigit(c)
                file += parse(Int, c)
            else
                sq = (8 - rank_idx) * 8 + file  # 0..63, A8=0
                piece = PIECE_MAP[c]
                bitboards[piece] |= UInt64(1) << sq
                file += 1
            end
        end
        @assert file == 8 "Each rank must have 8 squares"
    end

    # Side to move
    side_to_move = parts[2] == "w" ? WHITE : BLACK

    # Castling rights: KQkq as bits 0..3
    cr = UInt8(0)
    for c in parts[3]
        cr |= c == 'K' ? 0x1 : 0
        cr |= c == 'Q' ? 0x2 : 0
        cr |= c == 'k' ? 0x4 : 0
        cr |= c == 'q' ? 0x8 : 0
    end

    # En passant square
    ep = parts[4] == "-" ? -1 : square_index(parts[4])

    # Halfmove clock
    halfmove = length(parts) >= 5 ? parse(Int, parts[5]) : 0

    # Initialize Board
    # Construct preliminary board
    board = Board(
        bitboards,
        side_to_move,
        cr,
        ep,
        halfmove,
        UInt64[],    # position_history
        UndoInfo[],  # undo_stack
        0,           # eval_score placeholder
        0            # game_phase_value placeholder
    )

    # Compute cached values
    board.eval_score, board.game_phase_value = compute_eval_and_phase(board)

    return board
end