# ChessEngine.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://BjarkeHautop.github.io/ChessEngine.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://BjarkeHautop.github.io/ChessEngine.jl/dev/)
[![Build Status](https://github.com/BjarkeHautop/ChessEngine.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/BjarkeHautop/ChessEngine.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/BjarkeHautop/ChessEngine.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/BjarkeHautop/ChessEngine.jl)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![SciML Code Style](https://img.shields.io/static/v1?label=code%20style&message=SciML&color=9558b2&labelColor=389826)](https://github.com/SciML/SciMLStyle)

A Julia package that implements chess and a simple chess engine. It provides functionalities to represent the chessboard, validate moves, and evaluate positions.
Particularly, *ChessEngine* implements:

- All chess rules 
- Bitboard-based board representation  
- Legal move generation
- FEN parsing 
- Opening book support
- Minimax search with alpha–beta pruning and move ordering heuristics
- Evaluation function based on piece-square tables

## Resources

View the documentation at [https://BjarkeHautop.github.io/ChessEngine.jl/stable/](https://BjarkeHautop.github.io/ChessEngine.jl/stable/).

## To do

- Improve search algorithm (e.g., iterative deepening, quiescence search)

- Implement into Lichess bot (see https://github.com/lichess-bot-devs/lichess-bot)

- Improve API

- UCI?