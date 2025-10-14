# OrbisChessEngine.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://BjarkeHautop.github.io/OrbisChessEngine.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://BjarkeHautop.github.io/OrbisChessEngine.jl/dev/)
[![Build Status](https://github.com/BjarkeHautop/OrbisChessEngine.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/BjarkeHautop/OrbisChessEngine.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/BjarkeHautop/OrbisChessEngine.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/BjarkeHautop/OrbisChessEngine.jl)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![SciML Code Style](https://img.shields.io/static/v1?label=code%20style&message=SciML&color=9558b2&labelColor=389826)](https://github.com/SciML/SciMLStyle)

<p align="center">
  <img src="https://raw.githubusercontent.com/BjarkeHautop/OrbisChessEngine.jl/main/assets/logo.png" alt="Orbis Logo" width="200"/>
</p>

A Julia package that implements chess from scratch alongside a chess engine, **Orbis**. It provides functionalities to represent the chessboard, validate moves, and evaluate positions.
Particularly, *OrbisChessEngine* implements:

- All chess rules
- Bitboard representation
- Legal move generation (tested with [perft](https://www.chessprogramming.org/Perft))
- [FEN](https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation) parsing 
- Opening book support
- Minimax search with alpha–beta pruning, iterative deepening, quiescence search, transposition tables, null move pruning, and move ordering heuristics
- Evaluation function based on piece-square tables

## Resources

View the documentation at [https://BjarkeHautop.github.io/OrbisChessEngine.jl/dev/](https://BjarkeHautop.github.io/OrbisChessEngine.jl/dev/).

## TODO

- Soft time management; define optimal time and maximum time per move. Stop search when optimal time is reached after completing a depth or end immediately when maximum time is reached.

- Add support for multiple threads in search (e.g. lazy SMP)

- Implement (some of) [UCI](https://en.wikipedia.org/wiki/Universal_Chess_Interface) protocol

- Make executable with [PackageCompiler.jl](https://julialang.github.io/PackageCompiler.jl/dev/)

- Add magic bitboards for faster move generation

- Implement into Lichess bot (see https://github.com/lichess-bot-devs/lichess-bot)