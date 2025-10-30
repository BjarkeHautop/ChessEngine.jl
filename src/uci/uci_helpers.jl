# See https://www.wbec-ridderkerk.nl/html/UCIProtocol.html
# for the UCI protocol specification
# Need to modify search to support node limits, ponder mode, etc.
# Need to modify game struct to support different time increments for
# white and black, moves to next time control, etc.

function get_engine_version()
    proj_path = normpath(joinpath(@__DIR__, "..", "..", "Project.toml"))
    toml_text = read(proj_path, String)
    m = match(r"(?m)^version\s*=\s*\"([^\"]+)\"", toml_text)
    return m.captures[1]
end

function get_authors()
    proj_path = normpath(joinpath(@__DIR__, "..", "..", "Project.toml"))
    toml_text = read(proj_path, String)
    m = match(r"(?m)^\s*authors\s*=\s*\[([^\]]+)\]", toml_text)
    authors_str = m.captures[1]
    authors = [strip(replace(a, "\"" => "")) for a in split(authors_str, ",")]
    return authors
end

function id()
    version = get_engine_version()
    authors = join(get_authors(), ", ")
    println("id name OrbisChessEngine $version")
    println("id author $authors")
end

function handle_uci_command()
    # 1. Print engine identification
    id()  # prints name, version, author

    # 2. Print engine options
    # (none for now)

    # 3. Signal that UCI mode is ready
    println("uciok")
end

function handle_debug()
    println("debugging info")
    # Turn on verbose=true in search function to get more info?
end

function handle_isready()
    println("readyok")
end

function handle_setoption()
    # No options for now
    println("no options available")
end

function handle_register()
    println("register later")
end

function handle_position(command::String)
    tokens = split(command)
    board = nothing

    if tokens[2] == "startpos"
        board = Board()  # initialize starting position
        moves_index = findfirst(isequal("moves"), tokens)
    elseif tokens[2] == "fen"
        # collect FEN tokens (until "moves" or end of line)
        moves_index = findfirst(isequal("moves"), tokens)
        fen_tokens = moves_index === nothing ? tokens[3:end] : tokens[3:(moves_index - 1)]
        fen_string = join(fen_tokens, " ")
        board = Board(fen = fen_string)
    else
        error("invalid position command: must be startpos or fen")
    end

    # play moves if provided
    # ...

    return board
end

function handle_go(command::String, board)
    tokens = split(command)  # split by space
    search_params = Dict{String, Any}()

    i = 2  # skip "go"
    while i <= length(tokens)
        token = tokens[i]

        if token == "searchmoves"
            moves = String[]
            i += 1  # skip "searchmoves"
            while i <= length(tokens)
                tok = tokens[i]
                if occursin(r"^[a-h][1-8][a-h][1-8][qrbn]?$", tok) ||
                   uppercase(tok) in ["O-O", "O-O-O"]
                    push!(moves, tok)
                    i += 1
                else
                    break  # stop when we reach something that is NOT a move
                end
            end
            search_params["searchmoves"] = moves
            # All times are in milliseconds
        elseif token == "wtime"
            i += 1
            search_params["wtime"] = parse(Int, tokens[i])
        elseif token == "btime"
            i += 1
            search_params["btime"] = parse(Int, tokens[i])
            # Currently only have shared increment in Game struct
        elseif token == "winc"
            i += 1
            search_params["winc"] = parse(Int, tokens[i])
        elseif token == "binc"
            i += 1
            search_params["binc"] = parse(Int, tokens[i])
            # Number of moves until next time control
        elseif token == "movestogo"
            i += 1
            search_params["movestogo"] = parse(Int, tokens[i])
            # Depth to search
        elseif token == "depth"
            i += 1
            search_params["depth"] = parse(Int, tokens[i])
            # Number of nodes (positions) to search
        elseif token == "nodes"
            i += 1
            search_params["nodes"] = parse(Int, tokens[i])
            # Search for mate in x moves
            # Not implemented yet
        elseif token == "mate"
            i += 1
            search_params["mate"] = parse(Int, tokens[i])
            # Search for exactly this much time
            # Not implemented yet
        elseif token == "movetime"
            i += 1
            search_params["movetime"] = parse(Int, tokens[i])
            # Search until stopped
        elseif token == "infinite"
            search_params["infinite"] = true
            # Pondering mode
            # Not implemented yet
        elseif token == "ponder"
            search_params["ponder"] = true
        else
            # unknown token, skip
        end
        i += 1
    end
    # Call search with the implemented parameters
    # result = search(board; search_params...)
    println("bestmove e2e4")  # placeholder
end

function handle_stop()
    # Stop searching and return best move found
    println("bestmove e2e4")  # placeholder
end

function handle_ponderhit()
    # The user has played the expected move. This will be sent if the engine was told to ponder on the same move
    # the user has played. The engine should continue searching but switch from pondering to normal search.
    # Not implemented yet
    # search ...
    println("bestmove e2e4")  # placeholder
end

function handle_quit()
    exit(0)
end
