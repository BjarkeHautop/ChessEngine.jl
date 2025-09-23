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

function search_with_time(game::Game; max_depth::Int = 64, opening_book::Bool = true, verbose::Bool = false)
    allocated = allocate_time(game)
    stop_time = Int(time_ns() ÷ 1_000_000 + allocated)

    best_move = nothing
    best_score = 0

    for depth in 1:max_depth
        if (time_ns() ÷ 1_000_000) >= stop_time
            break
        end

        score,
        move = search(game.board, depth;
            ply = 0, α = (-MATE_VALUE), β = MATE_VALUE,
            opening_book = opening_book, verbose = verbose,
            stop_time = stop_time)

        if move !== nothing
            best_move = move
            best_score = score
        end

        if abs(best_score) >= MATE_THRESHOLD
            break
        end
    end

    return best_score, best_move
end

function make_timed_move!(game::Game; opening_book::Bool = true, verbose = false)
    start_time = time_ns() ÷ 1_000_000
    score, move = search_with_time(game; opening_book = opening_book, verbose = verbose)
    elapsed = (time_ns() ÷ 1_000_000) - start_time

    if move === nothing
        return score, move
    end

    make_move!(game.board, move)

    if game.board.side_to_move == BLACK
        game.white_time -= elapsed
        game.white_time += game.increment
    else
        game.black_time -= elapsed
        game.black_time += game.increment
    end

    return score, move
end

# Start a 5 min + 2 sec increment game
function start_game(; minutes = 5, increment = 2)
    initial_time = minutes * 60 * 1000  # convert to milliseconds
    board = start_position()
    return Game(board, initial_time, initial_time, increment * 1000)
end
