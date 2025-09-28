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

We can use `Move` to create a move. Several formats are supported:

```julia
mv = Move("e2", "e4")
mv_long_form = Move(board, "e2e4")
mv_manual = Move(12, 28)  # Coordinate format (0-63)
```

We can make a move using by `make_move` or the in-place version `make_move!`:

```julia
make_move!(board, mv)
```

The advantage of the mv_long_form above, is that you don't have to specify captures, promotions or castling, as these are inferred from the board position (hence it needs the board as an argument).

Here is e.g. how to make a capture move for the three different formats:

```julia
board = Board()
make_move!(board, Move("e2", "e4"))
make_move!(board, Move("d7", "d5"))

mv = Move("e4", "d5"; capture=B_PAWN)
mv_long_form = Move(board, "e4d5") 
mv_manual = Move(12, 28; capture=B_PAWN)
```

Hence the long form is often the most convenient.

We can undo a move using `undo_move!`:

```julia
undo_move!(board, mv)
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

