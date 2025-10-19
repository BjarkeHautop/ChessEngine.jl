Starting from version 0.1.2 of OrbisChessEngine this page shows benchmark results for perft for various depths.

## Benchmark Results

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
Seems to be slightly slower than the default implementation.
