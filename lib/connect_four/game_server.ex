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
  def init(_init_arg) do
    Process.set_label(:game)
    board = Board.new()
    game = Game.new(board)

    {:ok, %{game: game, clients: []}}
  end

  @impl GenServer
  def handle_call({:join, name}, {pid, _}, state) do
    case Game.add_player(state.game, name) do
      {:ok, game} ->
        Process.link(pid)
        next_state = %{state | game: game, clients: [{pid, name} | state.clients]}
        {:reply, :ok, next_state, {:continue, :push_to_clients}}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:drop_disc, name, column}, from, state) do
    case Game.drop_disc(state.game, name, column) do
      {:error, :not_player_turn} ->
        {:reply, {:error, :not_player_turn}, state}

      {:continue, game} ->
        {:reply, :ok, %{state | game: game}, {:continue, :push_to_clients}}

      {:won, _, game} ->
        Enum.each(state.clients, fn {client, name} ->
          send(client, {__MODULE__, %{name: name, game_state: game}})
          Process.unlink(client)
        end)

        GenServer.reply(from, :ok)

        {:stop, {:shutdown, :won}, %{state | game: game}}
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
end
