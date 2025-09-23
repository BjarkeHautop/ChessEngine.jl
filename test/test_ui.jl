using ChessEngine
using Test

@testset "display_board" begin
    b = start_position()

    # Expect no error
    display = display_board(b)
    @test typeof(display) == Makie.Figure
end
