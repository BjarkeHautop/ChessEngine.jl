b = start_position()

plot_history = Any[]
ply = 0
while game_over(b) == :ongoing
    if b.side_to_move == WHITE
        _, move = search(b, 5)
    else
        _, move = search(b, 3)
    end
    ply += 1
    println("Ply $ply")

    make_move!(b, move)
    plot_b = display_board(b)
    push!(plot_history, plot_b)
end

for pos in plot_history
    display(pos)
    sleep(1)
end

# Timed game against iself
g = start_game(minutes = 1, increment = 0)
plot_history = Any[]
while game_over(g.board) == :ongoing
    score, move = make_timed_move!(g; verbose = true)
    println("Score: $score")
    plot_g = display_board(g.board)
    push!(plot_history, plot_g)

    println("White time left: $(g.white_time/1000) seconds")
    println("Black time left: $(g.black_time/1000) seconds")
end

for pos in plot_history
    display(pos)
    sleep(1)
end
