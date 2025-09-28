# Getting Started

## Installation
Can not yet be installed using the Julia package manager. Clone the repository and use `] dev /path/to/ChessEngine` to install it.

## Playing Chess

First we load the package:

```julia
using ChessEngine
```

We can create a starting position using:

```julia
board = Board()
```

or load a game from a FEN string:

```julia
board = Board(fen="rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
```

This is a struct of type `Board` which contains the bitboards, side to move, castling rights, en passant square, halfmove clock, position history, undo stack, eval score and game phase value.

To display the board, we can use `display`:

```julia
display(board)
```

We can use `Move` to create a move. Several formats are supported, but the simplest is

```julia
mv = Move(board, "e2e4")
```

The advantage of the move format used above, is that you don't have to specify captures, promotions or castling, as these are inferred from the board position (hence it needs the board as an argument).

We can make a move using by `make_move` or the in-place version `make_move!`:

```julia
make_move!(board, mv)
```

We can undo a move using `undo_move` or the in-place version `undo_move!`:

```julia
undo_move!(board, mv)
```

Note, that `make_move` allows for illegal moves. (Add a check for legality later)?

You can check if the game is over using `game_over`:

```julia
game_over(board)
```

## Using the Engine

We can generate a move using the chess engine:

```julia
result = search(board; depth=3, opening_book=nothing)
```

`search` returns a `SearchResult` object containing the evaluation score, the move and if it is a book move. This package ships with a small opening book, which is default when calling `search`. To disable the opening book, set `opening_book=nothing`. To use a custom opening book use `load_polyglot_book` to load another polyglot book in `.bin` format.

To make a 3+2 game we can use:

```julia
game = Game(; minutes = 3, increment = 2)
```

or the shorter version:

```julia
game = Game("3+2")
```

This is a struct of type `Game` which contains the board, white and black time left, and the increment.

The engine will then automatically allocate how much time to use for each move. To make a move in the game we can use `make_timed_move!` (or the non-mutating version `make_timed_move`):

```julia
make_timed_move!(game)
```

