defmodule ConnectFour.GameClient.Web.WebsocketConnection do
  @behaviour WebSock

  @impl WebSock
  def init(init_arg) do
    name = Keyword.fetch!(init_arg, :name)

    Process.set_label({:game_client, name})

    {:ok, server} = ConnectFour.GameSupervisor.fetch_game_server()
    :ok = ConnectFour.GameServer.join(server, name)

    schedule_ping()

    {:ok, %{server: server, name: name}}
  end

  @impl WebSock
  def handle_in({msg, opcode: :text}, state) do
    {type, meta} = msg |> JSON.decode!() |> Map.pop!("type")
    {:ok, msgs, state} = handle_message(type, meta, state)
    {:push, to_json_messages(msgs), state}
  end

  defp handle_message("drop", %{"index" => index}, state) do
    case ConnectFour.GameServer.drop_disc(state.server, state.name, index) do
      :ok ->
        {:ok, [], state}

      {:error, _} = err ->
        msg = %{type: "error", reason: inspect(err)}
        {:ok, [msg], state}
    end
  end

  @impl WebSock
  def handle_info({ConnectFour.GameServer, data}, state) do
    Process.sleep(100)

    msg = %{
      players_turn: ConnectFour.State.Game.players_turn?(data.game_state, state.name),
      game_state: data.game_state
    }

    {:push, to_json_messages([msg]), state}
  end

  def handle_info(:ping, state) do
    schedule_ping()
    {:push, {:ping, ""}, state}
  end

  def handle_info({:EXIT, _, reason}, state) do
    {:stop, reason, state}
  end

  defp schedule_ping do
    Process.send_after(self(), :ping, :timer.seconds(30))
  end

  defp to_json_messages(msgs) do
    Enum.map(msgs, fn msg -> {:text, JSON.encode!(msg)} end)
  end
end
