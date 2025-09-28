using ChessEngine
using Test

@testset "Knight move generation" begin
    b = Board()

    # White knights at b1 and g1
    white_knight_moves = ChessEngine.generate_knight_moves(b)

    # Each knight has 2 moves at the starting position, so total 4 moves
    @test length(white_knight_moves) == 4

    expected_moves = [
        Move("b1", "a3"), Move("b1", "c3"), Move("g1", "f3"), Move("g1", "h3")
    ]

    for em in expected_moves
        @test em in white_knight_moves
    end
    make_move!(b, Move("b1", "c3"))

    black_knight_moves = ChessEngine.generate_knight_moves(b)
    @test length(black_knight_moves) == 4

    make_move!(b, Move("g8", "f6"))
    make_move!(b, Move("c3", "d5"))
    black_knight_moves = ChessEngine.generate_knight_moves(b)
    @test length(black_knight_moves) == 7

    capture_move = Move("f6", "d5"; capture = W_KNIGHT)
    @test capture_move in black_knight_moves
end

@testset "Knight move generation in place" begin
    b = Board()
    moves = Vector{Move}(undef, 256)
    n = ChessEngine.ChessEngine.generate_knight_moves!(b, moves)

    # Each knight has 2 moves at the starting position, so total 4 moves
    @test n == 4

    make_move!(b, Move("b1", "c3"))
    n = ChessEngine.ChessEngine.generate_knight_moves!(b, moves)
    @test n == 4

    make_move!(b, Move("g8", "f6"))
    make_move!(b, Move("c3", "d5"))

    n = ChessEngine.ChessEngine.generate_knight_moves!(b, moves)
    @test n == 7
end
