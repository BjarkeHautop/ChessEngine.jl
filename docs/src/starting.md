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

We can display the board using:

```julia
display_board(board)
```

We can make moves using:

```julia
mv = Move("e2", "e4")
make_move!(board, Move("e2", "e4"))
```

We can unmake a move using:

```julia
unmake_move!(board, mv)
```

We can generate a move using the chess engine:

```julia
_, best_move = search(board, depth=3)
```