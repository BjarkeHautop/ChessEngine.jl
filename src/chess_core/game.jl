# Game struct used for games with time control

"""
    Game

A struct representing a chess game with time control.

- board: The current state of the chess board.
- white_time: Time remaining for White in milliseconds.
- black_time: Time remaining for Black in milliseconds.
- increment: Time increment per move in milliseconds.
"""
mutable struct Game
    board::Board
    white_time::Int   # milliseconds remaining
    black_time::Int
    increment::Int    # per-move increment in ms
end

function time_mangement(move_time::Int, increment::Int)
    # Use current_time / 20 + increment / 2 as a heuristic for time management
    return move_time ÷ 20 + increment ÷ 2
end

function allocate_time(game::Game)
    side = game.board.side_to_move
    remaining = side == WHITE ? game.white_time : game.black_time
    return time_mangement(remaining, game.increment)
end

function search_with_time(
        game::Game;
        max_depth::Int = 64,
        opening_book::Union{Nothing, PolyglotBook} = KOMODO_OPENING_BOOK,
        verbose::Bool = false
)::SearchResult
    allocated = allocate_time(game)
    stop_time = Int(time_ns() ÷ 1_000_000 + allocated)

    best_result = SearchResult(nothing, nothing, false)

    for depth in 1:max_depth
        if (time_ns() ÷ 1_000_000) >= stop_time
            break
        end

        result = _search(game.board; depth,
            ply = 0, α = -MATE_VALUE, β = MATE_VALUE,
            opening_book = depth == 1 ? opening_book : nothing,  # book only at root
            stop_time = stop_time)

        # Propagate a book move immediately
        if result.from_book
            return result
        end

        if result.move !== nothing
            best_result = result
        end

        if abs(best_result.score) >= MATE_THRESHOLD
            return best_result
        end
    end

    return best_result
end

"""
    make_timed_move!(game::Game; opening_book::Union{Nothing, PolyglotBook}=KOMODO_OPENING_BOOK, verbose=false)

Make a move for the current player, updating the game state and time control.
- `game`: Game struct
- `opening_book`: Optional PolyglotBook for opening moves
- `verbose`: If true, print move details and time used
"""
function make_timed_move!(
        game::Game;
        opening_book::Union{Nothing, PolyglotBook} = KOMODO_OPENING_BOOK,
        verbose = false
)
    start_time = time_ns() ÷ 1_000_000
    result = search_with_time(game; opening_book = opening_book, verbose = verbose)
    elapsed = (time_ns() ÷ 1_000_000) - start_time

    if result.move === nothing
        return nothing
    end

    side_moved = game.board.side_to_move

    make_move!(game.board, result.move)

    if side_moved == WHITE
        game.white_time -= elapsed
        game.white_time += game.increment
    else
        game.black_time -= elapsed
        game.black_time += game.increment
    end
    if verbose
        println("Move made: ", result.move, " Score: ",
            result.score, " Time used (ms): ", elapsed)
        println("White time (ms): ", game.white_time, " Black time (ms): ", game.black_time)
    end
end

# Non-mutating version
"""
    make_timed_move(game::Game; opening_book::Union{Nothing, PolyglotBook}=KOMODO_OPENING_BOOK, verbose=false)

Make a move for the current player, returning a new Game state.
- `game`: Game struct
- `opening_book`: Optional PolyglotBook for opening moves
- `verbose`: If true, print move details and time used
"""
function make_timed_move(
        game::Game;
        opening_book::Union{Nothing, PolyglotBook} = KOMODO_OPENING_BOOK,
        verbose = false
)
    game_copy = deepcopy(game)
    make_timed_move!(game_copy; opening_book = opening_book, verbose = verbose)
    return game_copy
end

"""
Check for threefold repetition
- `board`: Board struct
Returns: Bool
"""
function is_threefold_repetition(board::Board)
    if isempty(board.position_history)
        return false
    end
    last_key = board.position_history[end]
    n = count(k -> k == last_key, board.position_history)
    return n >= 3
end

"""
Check for fifty-move rule
- `board`: Board struct
Returns: Bool
"""
function is_fifty_move_rule(board::Board)
    return board.halfmove_clock >= 100  # 100 plies = 50 full moves
end

"""
Check for insufficient material to mate
- `board`: Board struct
Returns: Bool
"""
function is_insufficient_material(board::Board)
    # Count pieces using bitboards
    function count_bits(bb::UInt64)
        return count_ones(bb)
    end

    # Quick check: any pawns, rooks, or queens → material is sufficient
    if count_bits(board.bitboards[Piece.W_PAWN]) > 0 ||
       count_bits(board.bitboards[Piece.B_PAWN]) > 0 ||
       count_bits(board.bitboards[Piece.W_ROOK]) > 0 ||
       count_bits(board.bitboards[Piece.B_ROOK]) > 0 ||
       count_bits(board.bitboards[Piece.W_QUEEN]) > 0 ||
       count_bits(board.bitboards[Piece.B_QUEEN]) > 0
        return false
    end

    # Count minor pieces
    w_minors = count_bits(board.bitboards[Piece.W_BISHOP]) +
               count_bits(board.bitboards[Piece.W_KNIGHT])
    b_minors = count_bits(board.bitboards[Piece.B_BISHOP]) +
               count_bits(board.bitboards[Piece.B_KNIGHT])

    # Only kings
    if w_minors == 0 && b_minors == 0
        return true
    end

    # King + single minor vs king
    if (w_minors == 1 && b_minors == 0) || (w_minors == 0 && b_minors == 1)
        return true
    end

    # King + bishop vs king + bishop (same color squares)
    if w_minors == 1 && b_minors == 1
        # Get bishop squares
        wb_sq = trailing_zeros(board.bitboards[Piece.W_BISHOP])
        bb_sq = trailing_zeros(board.bitboards[Piece.B_BISHOP])
        # Check square color: light=0, dark=1
        if (wb_sq % 8 + wb_sq ÷ 8) % 2 == (bb_sq % 8 + bb_sq ÷ 8) % 2
            return true
        end
    end

    return false
end

"""
    game_over(board::Board)

Check if the game is over (checkmate, stalemate, draw)
- `board`: Board struct
Returns: Symbol (:checkmate_white, :checkmate_black, :stalemate, :draw_threefold, :draw_fiftymove, 
:draw_insufficient_material, :ongoing)
"""
function game_over(board::Board)
    legal = generate_legal_moves(board)
    if isempty(legal)
        if in_check(board, board.side_to_move)
            return (board.side_to_move == WHITE) ? :checkmate_black : :checkmate_white
        else
            return :stalemate
        end
    end

    if is_insufficient_material(board)
        return :draw_insufficient_material

    elseif is_threefold_repetition(board)
        return :draw_threefold
    elseif is_fifty_move_rule(board)
        return :draw_fiftymove
    end

    return :ongoing
end

"""
    game_over(game::Game)

Check if the game is over (checkmate, stalemate, draw)
- `game`: Game struct
Returns: Symbol (:checkmate_white, :checkmate_black, :stalemate, :draw_threefold, :draw_fiftymove, 
:draw_insufficient_material, :ongoing)
"""
function game_over(game::Game)
    return game_over(game.board)
end
