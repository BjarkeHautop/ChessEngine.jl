using CairoMakie, Images, FileIO

# Path relative to this source file
const ASSET_DIR = abspath(joinpath(@__DIR__, "..", "assets"))

# Piece images used under CC BY-SA 3.0 license:
# Original source: https://commons.wikimedia.org/wiki/Category:PNG_chess_pieces/Standard_transparent
# License: https://creativecommons.org/licenses/by-sa/3.0/
# Changes: none

const PIECE_IMAGES = Dict(
    Piece.W_PAWN => joinpath(ASSET_DIR, "w_pawn.png"),
    Piece.W_KNIGHT => joinpath(ASSET_DIR, "w_knight.png"),
    Piece.W_BISHOP => joinpath(ASSET_DIR, "w_bishop.png"),
    Piece.W_ROOK => joinpath(ASSET_DIR, "w_rook.png"),
    Piece.W_QUEEN => joinpath(ASSET_DIR, "w_queen.png"),
    Piece.W_KING => joinpath(ASSET_DIR, "w_king.png"),
    Piece.B_PAWN => joinpath(ASSET_DIR, "b_pawn.png"),
    Piece.B_KNIGHT => joinpath(ASSET_DIR, "b_knight.png"),
    Piece.B_BISHOP => joinpath(ASSET_DIR, "b_bishop.png"),
    Piece.B_ROOK => joinpath(ASSET_DIR, "b_rook.png"),
    Piece.B_QUEEN => joinpath(ASSET_DIR, "b_queen.png"),
    Piece.B_KING => joinpath(ASSET_DIR, "b_king.png")
)

# (rotr90 to rotate images to match board orientation with rank 1 at bottom)
const PIECE_PIXELS = Dict(k => rotr90(load(v)) for (k, v) in PIECE_IMAGES)

# --- Display function ---
function display_board(board::Board)
    fig = Figure(; size = (600, 600))
    ax = CairoMakie.Axis(
        fig[1, 1];
        aspect = DataAspect()
    )

    ax.xticks = (collect(0.5:1:7.5), ["a", "b", "c", "d", "e", "f", "g", "h"])
    ax.yticks = (collect(0.5:1:7.5), ["1", "2", "3", "4", "5", "6", "7", "8"])

    # Colors
    light = RGB(0.93, 0.81, 0.65)
    dark = RGB(0.62, 0.44, 0.27)

    # Squares
    for rank in 1:8, file in 1:8

        color = isodd(rank + file) ? dark : light
        poly!(ax, Rect(file-1, rank-1, 1, 1); color = color)
    end

    # Pieces
    for (ptype, bb) in enumerate(board.bitboards)
        for sq in 0:63
            if testbit(bb, sq)
                file = (sq % 8) + 1
                rank = (sq ÷ 8) + 1
                img = PIECE_PIXELS[ptype]
                image!(ax, file-1 .. file, rank-1 .. rank, img)
            end
        end
    end

    hidespines!(ax)
    fig
end

import Base: display

function display(board::Board)
    display_board(board)
end

function display(game::Game)
    display_board(game.board)
end
