defimpl Enumerable, for: ConnectFour.State.Board do
  alias ConnectFour.State.Board

  def count(%Board{columns: columns}), do: {:ok, columns}
  def member?(%Board{}, _value), do: {:error, __MODULE__}
  def slice(%Board{}), do: {:error, __MODULE__}

  def reduce(%Board{} = board, acc, fun) do
    board.state
    |> Tuple.to_list()
    |> Enum.map(&Tuple.to_list/1)
    |> Enumerable.reduce(acc, fun)
  end
end
