# Game struct used for games with time control

"""
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

        result = _search(game.board, depth;
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

