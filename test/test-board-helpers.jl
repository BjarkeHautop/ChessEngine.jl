using OrbisChessEngine
using Test

@testset "Find capture piece" begin
    b = Board()
    piece_occ = OrbisChessEngine.find_capture_piece(b, 16, 1, 11)
    @test piece_occ == 0

    piece_occ = OrbisChessEngine.find_capture_piece(b, 0, 1, 11)
    @test piece_occ == Piece.W_ROOK
end
