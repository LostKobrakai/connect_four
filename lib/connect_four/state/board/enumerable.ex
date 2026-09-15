defimpl Enumerable, for: ConnectFour.State.Board do
  alias ConnectFour.State.Board

  def count(%Board{columns: columns}), do: {:ok, columns}
  def member?(%Board{}, _value), do: {:error, __MODULE__}
  def slice(%Board{}), do: {:error, __MODULE__}

  def reduce(%Board{} = board, acc, fun) do
    nested_lists =
      for x <- 1..board.columns//1 do
        for y <- 1..board.rows//1 do
          Map.fetch!(board.state, {x - 1, y - 1})
        end
      end

    Enumerable.reduce(nested_lists, acc, fun)
  end
end
