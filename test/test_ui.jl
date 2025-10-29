using OrbisChessEngine
using Test

@testset "plot_board" begin
    b = Board()
    g = Game()

    # Expect no error
    display_board = plot_board(b)
    display_game = plot_board(g)
    @test true
end

@testset "show board" begin
    b = Board()
    g = Game()

    # Expect no error
    display_board = show(b)
    display_game = show(g)
    @test true
end