defmodule ConnectFour.State.Board do
  defstruct [:columns, :rows, :streak_length, :state]

  def new(opts \\ []) do
    columns = Keyword.get(opts, :columns, 7)
    rows = Keyword.get(opts, :rows, 6)
    streak_length = Keyword.get(opts, :streak_length, 4)

    state =
      for x <- 1..columns//1, y <- 1..rows//1, into: %{} do
        {{x - 1, y - 1}, nil}
      end

    %__MODULE__{
      columns: columns,
      rows: rows,
      streak_length: streak_length,
      state: state
    }
  end

  def drop_disc(%__MODULE__{state: state} = board, column_index, player_index) do
    maybe_row_index =
      Enum.find(Range.new(0, board.rows - 1, 1), fn row_index ->
        nil == Map.fetch!(state, {column_index, row_index})
      end)

    case maybe_row_index do
      row_index when is_integer(row_index) ->
        next_state = Map.put(state, {column_index, row_index}, player_index)
        {:ok, {column_index, row_index}, %{board | state: next_state}}

      nil ->
        {:error, :column_full}
    end
  end

  def won_by?(%__MODULE__{streak_length: streak_length} = board, {cx, cy}, player_index) do
    search = List.duplicate(player_index, streak_length)
    possible_win_range = Range.new(-streak_length - 1, streak_length - 1, 1)

    Enum.any?([{0, 1}, {1, 0}, {1, 1}, {1, -1}], fn {dir_x, dir_y} ->
      possible_win_range
      |> Enum.map(fn mult -> Map.get(board.state, {cx + dir_x * mult, cy + dir_y * mult}) end)
      |> Enum.chunk_every(streak_length, 1, :discard)
      |> Enum.any?(fn maybe_streak -> search == maybe_streak end)
    end)
  end

  def moves_left?(%__MODULE__{state: state}) do
    Enum.any?(state, fn {_, value} -> value == nil end)
  end
end
