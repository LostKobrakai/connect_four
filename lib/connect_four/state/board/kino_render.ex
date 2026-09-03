defimpl Kino.Render, for: ConnectFour.State.Board do
  alias ConnectFour.State.Board

  def to_livebook(%Board{} = board) do
    board
    |> ConnectFour.Renderer.Ansi.render()
    |> IO.iodata_to_binary()
    |> Kino.Text.new(terminal: true)
    |> Kino.Render.Kino.Text.to_livebook()
  end
end
