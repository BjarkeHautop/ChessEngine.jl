module ChessEngine

include("types.jl")
include("opening_book.jl")
include("chess_core.jl")
include("evaluate_position.jl")
include("piece_square_tables.jl")
include("searchj.jl")

# Core types
export Board, UndoInfo, Move, Game, SearchResult

# Board setup & utility
export display_board

# Piece constants & colors
export W_PAWN, W_KNIGHT, W_BISHOP, W_ROOK, W_QUEEN, W_KING
export B_PAWN, B_KNIGHT, B_BISHOP, B_ROOK, B_QUEEN, B_KING
export WHITE, BLACK, ALL_PIECES

# Move generation & game state
export generate_legal_moves, generate_legal_moves!
export make_move!, make_move, undo_move!, undo_move, make_timed_move!
export in_check, game_over

# Evaluation & search
export evaluate, search, search_with_time

# Perft & testing
export perft, perft_fast

# Opening book
export PolyglotBook, load_polyglot_book
export book_move, polyglot_hash, KOMODO_OPENING_BOOK

end
