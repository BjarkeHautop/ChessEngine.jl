using ChessEngine
using Test

@testset "Polyglot position hash correct" begin
    b = Board()
    h = polyglot_hash(b)

    @test h == 0x463b96181691fc9c

    b = Board(fen="8/8/8/8/8/8/8/K7 b - - 0 1")
    h = polyglot_hash(b)

    @test h == 0x55b6344cf97aafae

    b = Board(fen="8/8/8/8/8/8/8/K1k5 b - - 0 1")
    h = polyglot_hash(b)

    @test h == 0x6f3e94b745caf3cd

    b = Board(fen="8/8/8/8/8/8/8/K1k5 w - - 0 1")
    h = polyglot_hash(b)

    @test h == 0x97e8b21deaed76c4

    b = Board(fen="4k3/8/8/8/8/8/8/4K2R w - - 0 1")
    h = polyglot_hash(b)

    @test h == 0x8f08c83346abde2c

    b = Board(fen="4k3/8/8/8/8/8/8/4K2R b K - 0 1")
    h = polyglot_hash(b)

    @test h == 0x4609f3578d3e9835
end

@testset "Polyglot hash with en_passant correct" begin
    b = Board()
    make_move!(b, Move("e2", "e5"))
    make_move!(b, Move("d7", "d5"))

    h = polyglot_hash(b)

    @test h == 0x826057c0f6443c7c
end
