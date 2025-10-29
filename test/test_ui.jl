using OrbisChessEngine
using Test

@testset "display_board" begin
    b = Board()
    g = Game()

    # Expect no error
    display_board = plot_board(b)
    display_game = plot_board(g)
    @test true
end
