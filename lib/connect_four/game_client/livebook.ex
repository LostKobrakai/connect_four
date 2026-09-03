defmodule ConnectFour.GameClient.Livebook do
  use GenServer, restart: :temporary

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  @impl GenServer
  def init(init_arg) do
    name = Keyword.fetch!(init_arg, :name)
    frame = Keyword.fetch!(init_arg, :frame)
    Process.set_label({:game_client, name})

    {:ok, server} = ConnectFour.GameSupervisor.fetch_game_server()
    :ok = ConnectFour.GameServer.join(server, name)
    {:ok, %{server: server, name: name, frame: frame}}
  end

  @impl GenServer
  def handle_info({{:button, index}, %{type: :click}}, state) do
    case ConnectFour.GameServer.drop_disc(state.server, state.name, index) do
      :ok -> :ok
      {:error, _} = err -> Kino.Frame.append(state.frame, err)
    end

    {:noreply, state}
  end

  def handle_info({ConnectFour.GameServer, data}, state) do
    Kino.Frame.render(state.frame, state.name)
    Kino.Frame.append(state.frame, data.game_state)

    if ConnectFour.State.Game.players_turn?(data.game_state, state.name) do
      Kino.Frame.append(state.frame, buttons(data.game_state))
    end

    {:noreply, state}
  end

  defp buttons(%ConnectFour.State.Game{} = game_state) do
    ConnectFour.Renderer.Ansi.buttons(game_state.board, fn control, column ->
      Kino.Control.subscribe(control, {:button, column - 1})
    end)
  end
end
