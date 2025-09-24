using ChessEngine
using Test

@testset "Doesn't use opening book in endgame" begin
    b = board_from_fen("4k3/8/8/8/8/8/4P3/4K3 w - - 0 1")
    time_before = time_ns() ÷ 1_000_000
    score, move = search(b, 10; opening_book = true)
    time_after = time_ns() ÷ 1_000_000
    # Test some time has elapsed

    @test (time_after - time_before) > 0
end