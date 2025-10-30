# Benchmarks

Starting from version 0.2.0 of OrbisChessEngine this page shows benchmark results for perft for various depths. Can be used to compare performance
with older versions.

## Benchmark Results for Perft

All benchmarks below are using a single thread. Perft uses the `Board` stuct from OrbisChessEngine, which means it computes
zobrist hash, and evaluation score at each node. Thus, it mimics the search process more closely than a pure move generator perft.

```@example
using OrbisChessEngine
using BenchmarkTools
b = Board()
perft(b, 5) # warm up
@benchmark perft($b, 5)
```

Using `perft_bishop_magic` which uses magic bitboards for bishop move generation:

```@example
using OrbisChessEngine
using BenchmarkTools
b = Board()
perft_bishop_magic(b, 5) # warm up
@benchmark perft_bishop_magic($b, 5)
```

Seems to be barely affect performance.

## Benchmark Results for Search

Benchmarking search to depth 10 from starting position:

```@example
using OrbisChessEngine
using BenchmarkTools
b = Board()
search(b; depth = 4) # warm up
@benchmark search($b; depth = 10, opening_book = nothing)
```
