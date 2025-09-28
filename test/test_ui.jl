using ChessEngine
using Test

@testset "display_board" begin
    b = Board()
    g = Game()

    # Expect no error
    display_board = ChessEngine.display_board(b)
    display_call = display(b)
    display_game = display(g)
    @test true
end
