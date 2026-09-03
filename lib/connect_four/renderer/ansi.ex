defmodule ConnectFour.Renderer.Ansi do
  alias ConnectFour.State.Board
  alias ConnectFour.State.Game

  @colors %{
    nil => :light_black,
    0 => :yellow,
    1 => :red
  }

  def render(game_or_board, opts \\ [])

  def render(%Board{} = board, opts) do
    board
    |> grid(opts)
    |> Enum.intersperse("\n")
    |> IO.ANSI.format()
  end

  def render(%Game{} = game, opts) do
    game
    |> layout(opts)
    |> Enum.intersperse("\n")
    |> IO.ANSI.format()
  end

  def grid(%Board{} = board, opts \\ []) do
    board
    |> Enum.zip_with(fn col -> col end)
    |> Enum.map(fn row ->
      row |> Enum.map(fn cell -> render_cell(cell, opts) end) |> Enum.intersperse(" ")
    end)
    |> Enum.reverse()
  end

  def layout(%Game{board: %Board{} = board} = game, opts \\ []) do
    spacer = "   "

    lines = grid(board, opts)

    joined_players =
      Enum.map(game.players, fn {name, player_index} ->
        formatted_name =
          case game.state do
            {:won, ^player_index} -> [name, " ", "👑"]
            {:turn, ^player_index} -> [name, " ", "<"]
            _ -> name
          end

        {player_index, formatted_name}
      end)

    open_player_slot =
      Enum.map(game.player_indexes, fn player_index ->
        {player_index, [:italic, "waiting for player", :reset]}
      end)

    legend =
      [joined_players, open_player_slot]
      |> Enum.concat()
      |> Enum.sort_by(fn {player_index, _} -> player_index end)
      |> Enum.map(fn {player_index, formatted_name} ->
        colors = Keyword.get(opts, :colors, @colors)
        [spacer, [Map.fetch!(colors, player_index), "●", :reset], " ", formatted_name]
      end)

    zip_longest_with(
      {lines, List.duplicate(" ", board.columns * 2 - 1)},
      {legend, []},
      fn [line, legend] -> line ++ legend end
    )
  end

  defp render_cell(player_index, opts) do
    colors = Keyword.get(opts, :colors, @colors)
    character = if player_index == nil, do: "○", else: "◉"
    [Map.fetch!(colors, player_index), character, :reset]
  end

  defp zip_longest_with({enumerable_a, filler_a}, {enumerable_b, filler_b}, callback) do
    [
      Stream.concat(enumerable_a, Stream.repeatedly(fn -> filler_a end)),
      Stream.concat(enumerable_b, Stream.repeatedly(fn -> filler_b end))
    ]
    |> Stream.zip_with(callback)
    |> Enum.take(max(Enum.count(enumerable_a), Enum.count(enumerable_b)))
  end

  def buttons(%Board{columns: columns}, callback \\ fn _, _ -> :ok end) do
    1..columns//1
    |> Enum.map(fn column ->
      control = Kino.Control.button("#{column}")
      callback.(control, column)
      control
    end)
    |> Kino.Layout.grid(columns: columns, boxed: true)
  end
end
