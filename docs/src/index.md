```@meta
CurrentModule = ChessEngine
```

# ChessEngine

[ChessEngine](https://github.com/BjarkeHautop/ChessEngine.jl) is a Julia chess engine. It implements functionality for playing chess and for searching for the best move
using the implemented chess engine.

## Features

- All chess rules
- Bitboard representation
- Legal move generation (tested with [perft](https://www.chessprogramming.org/Perft))
- [FEN](https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation) parsing 
- Opening book support
- Minimax search with alpha–beta pruning, iterative deepening, quiescence search, transposition tables, null move pruning, and move ordering heuristics
- Evaluation function based on piece-square tables

## Getting Started

See the [Getting Started](starting.md) page for installation instructions and basic usage examples.