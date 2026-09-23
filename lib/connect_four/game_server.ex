defmodule ConnectFour.GameServer do
  use GenServer, restart: :temporary
  alias ConnectFour.State.Board
  alias ConnectFour.State.Game

  # Client API

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  def join(game, name) do
    GenServer.call(game, {:join, name})
  end

  def drop_disc(game, name, column) do
    GenServer.call(game, {:drop_disc, name, column})
  end

  def game_state(game) do
    GenServer.call(game, :game)
  end

  # Server Callbacks

  @impl GenServer
  def init(init_arg) do
    lobby_registration = Keyword.get(init_arg, :lobby_registration)
    Process.set_label(:game)
    board = Board.new()
    game = Game.new(board)

    if lobby_registration do
      lobby_registration.register()
    end

    {:ok, %{game: game, clients: [], lobby_registration: lobby_registration}}
  end

  @impl GenServer
  def handle_call({:join, name}, {pid, _}, state) do
    case Game.add_player(state.game, name) do
      {:ok, game} ->
        Process.link(pid)
        next_state = %{state | game: game, clients: [{pid, name} | state.clients]}

        if state.lobby_registration && game.state != :setup do
          state.lobby_registration.unregister()
        end

        {:reply, :ok, next_state, {:continue, :push_to_clients}}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:drop_disc, name, column}, from, state) do
    case Game.drop_disc(state.game, name, column) do
      {:continue, game} ->
        {:reply, :ok, %{state | game: game}, {:continue, :push_to_clients}}

      {:won, _, game} ->
        GenServer.reply(from, :ok)
        {:stop, {:shutdown, :won}, %{state | game: game}}

      {:draw, game} ->
        GenServer.reply(from, :ok)
        {:stop, {:shutdown, :draw}, %{state | game: game}}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call(:game, {_pid, _}, state) do
    {:reply, state.game, state}
  end

  @impl GenServer
  def handle_continue(:push_to_clients, state) do
    Enum.each(state.clients, fn {client, name} ->
      send(client, {__MODULE__, %{name: name, game_state: state.game}})
    end)

    {:noreply, state}
  end

  @impl GenServer
  def terminate({:shutdown, _reason}, state) do
    Enum.each(state.clients, fn {client, name} ->
      send(client, {__MODULE__, %{name: name, game_state: state.game}})
      Process.unlink(client)
    end)
  end

  def terminate(_reason, _state), do: :ok
end
