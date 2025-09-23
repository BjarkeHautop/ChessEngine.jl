module ChessEngine

include("chess_core.jl")

export UndoInfo, Board, start_position, square_index, setbit, clearbit, testbit,
       position_equal
export W_PAWN, W_KNIGHT, W_BISHOP, W_ROOK, W_QUEEN, W_KING
export B_PAWN, B_KNIGHT, B_BISHOP, B_ROOK, B_QUEEN, B_KING
export ALL_PIECES
export WHITE, BLACK
export board_from_fen

export Move, generate_pawn_moves, generate_knight_moves, generate_bishop_moves
export generate_rook_moves, generate_queen_moves, generate_king_moves
export generate_legal_moves, make_move!, game_over, in_check
export square_attacked, king_square, piece_at
export display_board
export zobrist_hash
export unmake_move!
include("piece_square_tables.jl")
export flip_table
export piece_square_value

include("evaluate_position.jl")
export evaluate, search, compute_eval_and_phase

include("opening_book.jl")
export play_move, book_move, polyglot_hash, polyglot_piece_index, OPENING_BOOK
export POLYGLOT_RANDOM_ARRAY, WHITE_KING, WHITE_QUEEN, BLACK_KING, BLACK_QUEEN

include("searchj.jl")
include("game.jl")
export Game, make_timed_move!, search_with_time, start_game, MATE_VALUE, MATE_THRESHOLD
end
