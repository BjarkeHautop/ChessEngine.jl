using OrbisChessEngine
using Test

@testset "Game Time Management" begin
    game = Game(minutes = 0.5, increment = 2)

    @test isa(game, Game)
    @test game.white_time == 0.5*60*1000
    @test game.black_time == 0.5*60*1000
    @test game.increment == 2000

    allocated = OrbisChessEngine.allocate_time(game)
    @test isa(allocated, Int)
    @test allocated > 0

    # Test make_timed_move!
    old_white_time = game.white_time
    make_timed_move!(game; opening_book = nothing)
    @test game.board.side_to_move == BLACK
    @test game.white_time < old_white_time + game.increment  # elapsed time subtracted

    old_black_time = game.black_time
    make_timed_move!(game; opening_book = nothing)
    @test game.board.side_to_move == WHITE
    @test game.black_time < old_black_time + game.increment
end

@testset "Time management heuristic" begin
    @test OrbisChessEngine.time_mangement(20000, 2000) == 20000 ÷ 20 + 2000 ÷ 2
    @test OrbisChessEngine.time_mangement(1000, 0) == 1000 ÷ 20
end

@testset "Search with time respects allocation" begin
    game = Game(minutes = 1, increment = 0)
    make_timed_move!(game; opening_book = nothing)

    # Should have spent 60000 ms / 20 = 3000ms on first move and then some overhead thus, 56000 < game.white_time < 57000
    @test game.white_time <= 57000
    @test game.white_time > 56000
end

@testset "Search with time opening book move" begin
    game = Game(minutes = 1, increment = 0)
    make_timed_move!(game)

    # Should have played an opening book move and not spent any time
    @test game.white_time > 59000
    @test game.board.side_to_move == BLACK
end

@testset "Search with time Fools mate" begin
    # Fool's mate position after 1. f3 e5 2. g4 Qh4#
    game = Game(fen = "rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq g3 0 1")
    make_timed_move!(game; opening_book = nothing)

    # Should have played Qh4#
    @test game_status(game.board) == :checkmate_black
end

@testset "Search with time verbose works" begin
    game = Game(minutes = 1, increment = 0)
    make_timed_move!(game; opening_book = nothing, verbose = true)
    @test game.board.side_to_move == BLACK
end

@testset "Search with time non mutating" begin
    game = Game(minutes = 1, increment = 0)
    result = search_with_time(game; max_depth = 4, opening_book = nothing, verbose = false)
    @test isa(result, SearchResult)
    @test result.move !== nothing
    @test game.board.side_to_move == WHITE  # game not mutated
end

@testset "Make timed move non mutating" begin
    game = Game(minutes = 1, increment = 0)
    old_board = deepcopy(game.board)
    make_timed_move(game)
    @test game.board.side_to_move == WHITE  # game not mutated
    @test game.board == old_board  # board unchanged
end

@testset "Make timed move no time left" begin
    game = Game(minutes = 0, increment = 0)
    old_board = deepcopy(game.board)
    make_timed_move!(game; opening_book = nothing)
    @test game.board == old_board  # no move made
    @test game.white_time == 0
end