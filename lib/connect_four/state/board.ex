defmodule ConnectFour.State.Board do
  defstruct [:columns, :rows, :streak_length, :state]

  def new(opts \\ []) do
    columns = Keyword.get(opts, :columns, 7)
    rows = Keyword.get(opts, :rows, 6)
    streak_length = Keyword.get(opts, :streak_length, 4)

    state_column = List.duplicate(nil, rows)

    state =
      state_column
      |> List.to_tuple()
      |> List.duplicate(columns)
      |> List.to_tuple()

    %__MODULE__{
      columns: columns,
      rows: rows,
      streak_length: streak_length,
      state: state
    }
  end

  def drop_disc(%__MODULE__{state: state} = board, column_index, player_index) do
    column = elem(state, column_index)

    column
    |> Tuple.to_list()
    |> Enum.split_while(fn x -> x != nil end)
    |> case do
      {taken, [nil | rest]} ->
        new_column = List.to_tuple(taken ++ [player_index | rest])
        board = %__MODULE__{board | state: put_elem(state, column_index, new_column)}
        {:ok, {column_index, length(taken)}, board}

      {_taken, []} ->
        {:error, :column_full, board}
    end
  end

  def won?(%__MODULE__{} = board, coordinate, player_index) do
    streak = 4
    streak_steps = Range.new((streak - 1) * -1, streak - 1, 1)

    Enum.any?(directions(), fn direction ->
      streak_steps
      |> Enum.reduce_while(0, fn streak_step, acc ->
        check_coordinate =
          direction
          |> vec_mult(streak_step)
          |> vec_add(coordinate)

        next_acc =
          case fetch_player(board, check_coordinate) do
            {:ok, ^player_index} -> acc + 1
            _ -> 0
          end

        if next_acc >= streak do
          {:halt, :won}
        else
          {:cont, next_acc}
        end
      end)
      |> Kernel.==(:won)
    end)
  end

  defp directions do
    [
      # horizontal
      {1, 0},
      # vertical
      {0, 1},
      # raising diagonal
      {1, 1},
      # falling diagonal
      {1, -1}
    ]
  end

  def fetch_player(board, {x, y}) do
    {:ok, board.state |> elem(x) |> elem(y)}
  rescue
    ArgumentError -> :error
  end

  def vec_add({x, y}, {a, b}), do: {x + a, y + b}
  def vec_mult({x, y}, a), do: {x * a, y * a}
end
