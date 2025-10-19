# Getting Started

## Installation
The OrbisChessEngine package is available through the Julia package system by running Pkg.add("OrbisChessEngine"). Throughout, we assume that you have installed the package.

## Playing Chess

First we load the package:

```julia
using OrbisChessEngine
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

Note, that `make_move` allows for illegal moves. You can get all legal moves using `generate_legal_moves`:

```julia
legal_moves = generate_legal_moves(board)
```

You can check the game status using `game_status`:

```julia
game_status(board)
```

## Using the Engine

To generate a move using the engine we can use `search`:

```julia
result = search(board; depth=3, opening_book=nothing)
```

`search` returns a `SearchResult` object containing the evaluation score, the move and if it is a book move. This package ships with a small opening book, which is default when calling `search`. To disable the opening book, set `opening_book=nothing`. To use a custom opening book use `load_polyglot_book` to load another polyglot book in `.bin` format.

To make a 3+2 game we can use `Game`:

```julia
game = Game(; minutes = 3, increment = 2)
```

or the short-hand notation:

```julia
game = Game("3+2")
```

This is a struct of type `Game` which contains the board, white and black time left, and the increment.

The engine will then automatically allocate how much time to use for each move. To let the engine make a move in a timed game we can use `make_timed_move!`:

```julia
make_timed_move!(game)
```

Combining everything we can let the engine play against itself in a 1+1 game:

```julia
game = Game("1+1")
plots = []
while game_status(game.board) == :ongoing
    make_timed_move!(game)
    push!(plots, display(game))
end
```

And view the game:

```julia
for i in eachindex(plots)
    sleep(0.5)
    display(plots[i])
end
```

