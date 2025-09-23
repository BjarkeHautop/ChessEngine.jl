b = start_postition()

make_move!(b, Move("c2", "c4"))
display_board(b)
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("g2", "g3"))
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("f1", "g2"))
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("g1", "f3"))
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("e1", "g1"; castling = 1))
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("d2", "d3"))
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("a2", "a3"))
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("d3", "c4"; capture = B_PAWN))
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("g1", "f2"; capture = B_BISHOP))
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("d1", "d4"))
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("b1", "c3"))
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("f2", "g1"))
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("e2", "e4"))
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("c3", "e4"; capture = B_PAWN))
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("b2", "b4"))
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("b8", "a6"))
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("c1", "b2"))
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("f3", "e5"; capture = B_PAWN))
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("d4", "e5"; capture = B_KNIGHT))
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("g1", "g2"; capture = B_QUEEN))
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("g2", "h3"; capture = B_BISHOP))
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("f1", "f7"; capture = B_ROOK))
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("a1", "f1"))
mv = play_move(b)
make_move!(b, mv)
display_board(b)

make_move!(b, Move("e5", "g5"))
mv = play_move(b)
make_move!(b, mv)
display_board(b)
