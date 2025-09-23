# Read https://gist.github.com/DOBRO/2592c6dad754ba67e6dcaec8c90165bf

"""
Parse a UCI move string like "e2e4" or "e7e8q" into a Move.
"""
function parse_uci_move(str::AbstractString, board::Board)
    from_str = str[1:2]
    to_str = str[3:4]

    promotion = 0
    castling = 0
    en_passant = false

    # Promotion piece (if any)
    if length(str) == 5
        promo_char = str[5]
        promotion = promotion_from_char(promo_char, board.side_to_move)
    end

    # Castling detection (optional)
    if (from_str == "e1" && to_str == "g1") || (from_str == "e8" && to_str == "g8")
        castling = 1 # kingside
    elseif (from_str == "e1" && to_str == "c1") || (from_str == "e8" && to_str == "c8")
        castling = 2 # queenside
    end

    return Move(from_str, to_str; promotion = promotion,
        castling = castling, en_passant = en_passant)
end

"""
Map promotion character ('q','r','b','n') and side to the correct piece constant.
"""
function promotion_from_char(c::Char, side_to_move::Symbol)
    c = lowercase(c)
    if side_to_move == :white
        return c == 'q' ? W_QUEEN :
               c == 'r' ? W_ROOK :
               c == 'b' ? W_BISHOP :
               c == 'n' ? W_KNIGHT : 0
    else
        return c == 'q' ? B_QUEEN :
               c == 'r' ? B_ROOK :
               c == 'b' ? B_BISHOP :
               c == 'n' ? B_KNIGHT : 0
    end
end

function uci_loop()
    board = start_position()
    game = nothing

    while true
        line = readline(stdin, keep = true)
        line = strip(line)
        if line == "uci"
            println("id name MyJuliaEngine")
            println("id author Bjarke Hautop")
            println("uciok")

        elseif line == "isready"
            println("readyok")

        elseif startswith(line, "position")
            # Example: "position startpos moves e2e4 e7e5"
            parts = split(line)
            if parts[2] == "startpos"
                board = start_position()
                moves_index = findfirst(==("moves"), parts)
                if moves_index !== nothing
                    for mv in parts[(moves_index + 1):end]
                        make_move!(board, parse_uci_move(mv, board))
                    end
                end
            else
                # "position fen <fenstring> ..."
                fen = join(parts[3:8], " ")
                board = position_from_fen(fen)
                moves_index = findfirst(==("moves"), parts)
                if moves_index !== nothing
                    for mv in parts[(moves_index + 1):end]
                        make_move!(board, parse_uci_move(mv, board))
                    end
                end
            end

        elseif startswith(line, "go")
            # Defaults if not provided
            wtime = 0
            btime = 0
            winc = 0
            binc = 0
            movestogo = 0
            depth = 0  # optional depth limit

            parts = split(line)
            i = 2
            while i <= length(parts)
                if parts[i] == "wtime"
                    wtime = parse(Int, parts[i + 1])
                    i += 2
                elseif parts[i] == "btime"
                    btime = parse(Int, parts[i + 1])
                    i += 2
                elseif parts[i] == "winc"
                    winc = parse(Int, parts[i + 1])
                    i += 2
                elseif parts[i] == "binc"
                    binc = parse(Int, parts[i + 1])
                    i += 2
                elseif parts[i] == "movestogo"
                    movestogo = parse(Int, parts[i + 1])
                    i += 2
                elseif parts[i] == "depth"
                    depth = parse(Int, parts[i + 1])
                    i += 2
                else
                    i += 1
                end
            end

            if game === nothing
                game = start_uci_game(board, wtime, btime, winc, binc)
            else
                # just update times if GUI sends wtime/btime
                game.white_time = wtime
                game.black_time = btime
            end

            # Make the timed move
            score, move = make_timed_move!(g; depth = depth, verbose = false)

            # Apply move to board
            make_move!(board, move)

            # Reply to GUI
            println("bestmove $(move_to_uci(move))")

        elseif line == "quit"
            break
        end
    end
end

function start_uci_game(
        board::Board, wtime_ms::Int, btime_ms::Int, winc_ms::Int, binc_ms::Int)
    return Game(board, wtime_ms, btime_ms, max(winc_ms, binc_ms)) # use max increment for simplicity
    # Fix later
end

"""
Convert an internal Move back into UCI string like "e2e4" or "e7e8q".
"""
function move_to_uci(m::Move)
    from_str = square_name(m.from)
    to_str = square_name(m.to)
    str = from_str * to_str

    if m.promotion != 0
        str *= promotion_to_char(m.promotion)
    end

    return str
end

"""
Map internal promotion piece constant to UCI char ('q','r','b','n').
"""
function promotion_to_char(piece::Int)
    if piece in (W_QUEEN, B_QUEEN)
        return "q"
    elseif piece in (W_ROOK, B_ROOK)
        return "r"
    elseif piece in (W_BISHOP, B_BISHOP)
        return "b"
    elseif piece in (W_KNIGHT, B_KNIGHT)
        return "n"
    else
        return ""
    end
end
using PkgTemplates
Template(interactive=true)("MyTestPkg")
