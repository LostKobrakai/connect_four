defimpl Kino.Render, for: ConnectFour.State.Game do
  alias ConnectFour.State.Game

  def to_livebook(%Game{} = game) do
    game
    |> ConnectFour.Renderer.Ansi.render()
    |> IO.iodata_to_binary()
    |> Kino.Text.new(terminal: true)
    |> Kino.Render.Kino.Text.to_livebook()
  end
end
