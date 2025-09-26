# Getting Started

## Installation
Can not yet be installed using the Julia package manager. Clone the repository and use `] dev /path/to/ChessEngine` to install it.

## Playing Chess

First we load the package:

```julia
using ChessEngine
```

We can create a new chess game using:

```julia
board = start_position()
```

or load a game from a FEN string:

```julia
board = board_from_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
```

This is a struct of type `Board` which contains the bitboards, side to move, castling rights, en passant square, halfmove clock, position history, undo stack, eval score and game phase value.

To display the board, we can use:

```julia
display_board(board)
```

We can use `Move` to create a move and `make_move!` to make the move on the board:

```julia
mv = Move("e2", "e4")
make_move!(board, mv)
```

We can undo a move using `undo_move!`:

```julia
undo_move!(board, mv)
```

We can generate a move using the chess engine:

```julia
result = search(board, depth=3; opening_book=nothing)
```

`search` returns a `SearchResult` object containing the evaluation score, the move and if it is a book move. This package ships with a small opening book, which is default when calling `search`. To disable the opening book, set `opening_book=nothing` and to use a custom opening book use `load_polyglot_book` to load another polyglot book in `.bin` format.

To make a 3+2 game we can use:

```julia
game = start_game(; minutes = 3, increment = 2)
```

This is a struct of type `Game` which contains the board, white and black time left, and the increment.

The engine will then automatically allocate how much time to use for each move. To make a move in the game we can use:

```julia
make_timed_move!(game)
```