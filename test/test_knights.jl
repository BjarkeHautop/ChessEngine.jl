using ChessEngine
using Test

@testset "Knight move generation" begin
    b = start_position()

    # White knights at b1 and g1
    white_knight_moves = generate_knight_moves(b)

    # Each knight has 2 moves at the starting position, so total 4 moves
    @test length(white_knight_moves) == 4

    expected_moves = [
        Move("b1", "a3"), Move("b1", "c3"), Move("g1", "f3"), Move("g1", "h3")
    ]

    for em in expected_moves
        @test em in white_knight_moves
    end

    # Black knights at b8 and g8
    black_knight_moves = generate_knight_moves(b)
    @test length(black_knight_moves) == 4
end
