using Test
using OrbisChessEngine

@testset "handle_uci_command output" begin
    original_stdout = stdout
    (read_pipe, write_pipe) = redirect_stdout()  # capture stdout

    OrbisChessEngine.handle_uci_command()

    redirect_stdout(original_stdout)
    close(write_pipe)

    output = read(read_pipe, String)
    lines = split(strip(output), '\n')

    @test length(lines) == 3

    # Line 1: check engine name and version
    @test occursin(r"OrbisChessEngine \d+\.\d+\.\d+-DEV", lines[1])

    # Line 2: check author
    @test occursin("Bjarke Hautop", lines[2])

    # Line 3: check uciok
    @test occursin("uciok", lines[3])
end

@testset "Call various uci_helpers" begin
    # They do nothing for now, just ensure no errors
    OrbisChessEngine.handle_debug()
    OrbisChessEngine.handle_isready()
    OrbisChessEngine.handle_setoption()
    OrbisChessEngine.handle_register()
    OrbisChessEngine.handle_stop()
    OrbisChessEngine.handle_ponderhit()
    @test true
end

@testset "handle_position" begin
    board = OrbisChessEngine.handle_position("position startpos")
    @test OrbisChessEngine.position_equal(Board(), board)

    fen = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
    board = OrbisChessEngine.handle_position("position fen $fen")
    @test OrbisChessEngine.position_equal(Board(fen = fen), board)

    @test_throws ErrorException OrbisChessEngine.handle_position("position invalidcommand")
end

@testset "handle_go" begin
    b = Board()
    command = "searchmoves e2e4 d7d5 e4d5 ponder e2e4 wtime " *
              "30000 btime 30000 winc 100 binc 100 movestogo 5 " *
              "depth 5 nodes 10000 mate 3 movetime 2000 infinite " *
              "unknowncommand"
    OrbisChessEngine.handle_go(command, b)
end
