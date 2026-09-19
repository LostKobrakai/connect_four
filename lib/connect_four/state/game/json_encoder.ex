defimpl JSON.Encoder, for: ConnectFour.State.Game do
  alias ConnectFour.State.Board
  alias ConnectFour.State.Game

  def encode(%Game{board: %Board{} = board} = game, encoder) do
    encoder.(
      %{
        state: encode_state(game.state),
        board: board_to_json(board),
        players: players_to_json(game)
      },
      encoder
    )
  end

  defp encode_state(:setup), do: "setup"
  defp encode_state({:turn, index}), do: ["turn", index]
  defp encode_state({:won, index}), do: ["won", index]
  defp encode_state(:draw), do: "draw"

  defp players_to_json(%Game{players: players, player_indexes: pending}) do
    total = map_size(players) + length(pending)
    by_index = Map.new(players, fn {name, index} -> {index, name} end)
    for index <- 0..(total - 1), do: Map.get(by_index, index)
  end

  defp board_to_json(%Board{} = board) do
    %{
      columns: board.columns,
      rows: board.rows,
      streak_length: board.streak_length,
      state: for({{x, y}, value} <- board.state, into: %{}, do: {y * board.columns + x, value})
    }
  end
end
