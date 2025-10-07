using OrbisChessEngine
using Test

@testset "Game over detection" begin
    b = Board()

    @test game_status(b) == :ongoing

    # Fool's mate position (black wins)
    moves = [
        Move(OrbisChessEngine.square_index(6, 2), OrbisChessEngine.square_index(6, 3)),  # f2 to f3
        Move(OrbisChessEngine.square_index(5, 7), OrbisChessEngine.square_index(5, 5)),  # e7 to e5
        Move(OrbisChessEngine.square_index(7, 2), OrbisChessEngine.square_index(7, 4)),  # g2 to g4
        Move(OrbisChessEngine.square_index(4, 8), OrbisChessEngine.square_index(8, 4))  # d8 to h4 (checkmate)
    ]

    for m in moves
        make_move!(b, m)
    end

    # Check game over status
    @test game_status(b) == :checkmate_black  # white is checkmated
    b.side_to_move = BLACK  # switch to black
    @test game_status(b) == :ongoing  # black is not checkmated

    # -----------------------------
    # Stalemate example: king vs king + pawn
    # -----------------------------
    # Create a simple stalemate position: black king on b8, white king on b6, white pawn on b7
    bitboards = Dict{Int, UInt64}()

    # Initialize all piece types to 0
    for p in Piece.W_PAWN:Piece.B_KING
        bitboards[p] = UInt64(0)
    end

    # Place the pieces
    bitboards[Piece.W_KING] = OrbisChessEngine.setbit(UInt64(0), OrbisChessEngine.square_index(2, 6))  # b6
    bitboards[Piece.W_PAWN] = OrbisChessEngine.setbit(UInt64(0), OrbisChessEngine.square_index(2, 7))  # b7
    bitboards[Piece.B_KING] = OrbisChessEngine.setbit(UInt64(0), OrbisChessEngine.square_index(2, 8))  # b8

    # Black to move, no castling rights, no en passant
    b = Board(bitboards, BLACK, 0x0, -1, 0, UInt64[], UndoInfo[], 0, 0)
    @test game_status(b) == :stalemate
    b.side_to_move = WHITE  # switch to white
    @test game_status(b) == :ongoing

    # -----------------------------
    # Threefold repetition example
    # -----------------------------
    # Shuffle knights back and forth from starting position
    b = Board()
    moves = [
        Move(OrbisChessEngine.square_index(2, 1), OrbisChessEngine.square_index(3, 3)),  # b1 to c3
        Move(OrbisChessEngine.square_index(7, 8), OrbisChessEngine.square_index(6, 6)),  # g8 to f6
        Move(OrbisChessEngine.square_index(3, 3), OrbisChessEngine.square_index(2, 1)),  # c3 to b1
        Move(OrbisChessEngine.square_index(6, 6), OrbisChessEngine.square_index(7, 8))  # f6 to g8
    ]
    for i in 1:3
        for m in moves
            make_move!(b, m)
        end
    end
    @test game_status(b) == :draw_threefold
    b.side_to_move = BLACK
    @test game_status(b) == :draw_threefold

    # -----------------------------
    # Fifty-move rule example
    # -----------------------------
    # Start with a board with only kings and 1 rook
    bitboards = Dict{Int, UInt64}()
    for p in Piece.W_PAWN:Piece.B_KING
        bitboards[p] = UInt64(0)
    end
    bitboards[Piece.W_KING] = OrbisChessEngine.setbit(UInt64(0), OrbisChessEngine.square_index(5, 1))  # e1
    bitboards[Piece.B_KING] = OrbisChessEngine.setbit(UInt64(0), OrbisChessEngine.square_index(5, 8))  # e8
    bitboards[Piece.W_ROOK] = OrbisChessEngine.setbit(UInt64(0), OrbisChessEngine.square_index(1, 1))  # a1

    # Make a board with 98 halfmoves (49 full moves) without pawn moves or captures
    b = Board(bitboards, WHITE, 0x0, -1, 98, UInt64[], UndoInfo[], 0, 0)
    @test game_status(b) == :ongoing
    b.side_to_move = BLACK
    @test game_status(b) == :ongoing

    b.side_to_move = WHITE

    # Now make the 99th and 100th halfmove
    moves = [
        Move(OrbisChessEngine.square_index(5, 1), OrbisChessEngine.square_index(5, 2)),  # e1 to e2
        Move(OrbisChessEngine.square_index(5, 8), OrbisChessEngine.square_index(5, 7))  # e8 to e7
    ]
    for m in moves
        make_move!(b, m)
    end
    @test game_status(b) == :draw_fiftymove
    b.side_to_move = BLACK
    @test game_status(b) == :draw_fiftymove
end

@testset "Insufficent material" begin
    b = Board(fen = "4k3/8/8/8/8/8/8/4K3 w - - 0 1")  # King vs King
    @test game_status(b) == :draw_insufficient_material

    b = Board(fen = "4k3/8/2b5/8/8/8/2B5/4K3 w - - 0 1") # King and Bishop vs King and Bishop (same color)
    @test game_status(b) == :draw_insufficient_material

    b = Board(fen = "4k3/8/8/8/8/2N5/8/4K3 w - - 0 1") # King and Knight vs King
    @test game_status(b) == :draw_insufficient_material
end

@testset "Not insufficent material" begin
    b = Board(fen = "5k2/8/4K3/4B3/4N3/8/8/8 b - - 0 1") # King, Bishop, Knight vs King
    @test OrbisChessEngine.is_insufficient_material(b) == false

    g = Game()
    @test game_status(g) == :ongoing
end

@testset "Game status time out" begin
    g = Game()
    g.white_time = 0  # Simulate white running out of time
    @test game_status(g) == :timeout_white

    g = Game()
    g.black_time = 0  # Simulate black running out of time
    @test game_status(g) == :timeout_black
end
