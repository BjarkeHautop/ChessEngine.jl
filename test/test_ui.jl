using ChessEngine
using Test

@testset "display_board" begin
    b = Board()

    # Expect no error
    display = display_board(b)
    @test true
end
