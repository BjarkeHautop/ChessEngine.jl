using ChessEngine
using Test

@testset "Game api" begin
    g = Game()
    new_g = Game("3+2")

    @test g.board == new_g.board
    @test g.white_time == new_g.white_time == 180_000
    @test g.black_time == new_g.black_time == 180_000
    @test g.increment == new_g.increment == 2000
end

@testset "Move api" begin
    b = Board()
    m = Move(b, "e2e4")
    @test m.from == 12
    @test m.to == 28
    @test string(m) == "e2e4"

    m2 = Move(b, "e7e8=Q")
    @test m2.from == 52
    @test m2.to == 60
    @test m2.promotion == W_QUEEN
    @test string(m2) == "e7e8=Q"

    m3 = Move(b, "O-O")
    @test m3.from == 4
    @test m3.to == 6
    @test m3.castling == 1
    @test string(m3) == "O-O"

    m4 = Move(b, "O-O-O")
    @test m4.from == 4
    @test m4.to == 2
    @test m4.castling == 2
    @test string(m4) == "O-O-O"

    @test_throws ErrorException Move(b, "e7e8=Z")
end

@testset "Move api works with make_move" begin
    b = Board()
    m = Move(b, "e2e4")
    new_b = make_move(b, m)
    make_move!(b, m)
    @test ChessEngine.piece_at(b, 28) == ChessEngine.piece_at(new_b, 28) == W_PAWN
    @test ChessEngine.piece_at(b, 12) == ChessEngine.piece_at(new_b, 12) == 0
end
