defmodule ConnectFour.GameSupervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Registry, keys: :duplicate, name: ConnectFour.GameSupervisor.Lobby},
      {DynamicSupervisor, name: ConnectFour.GameSupervisor.Dynamic, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def fetch_game_server() do
    case Registry.lookup(ConnectFour.GameSupervisor.Lobby, :lobby) do
      [] ->
        DynamicSupervisor.start_child(
          ConnectFour.GameSupervisor.Dynamic,
          {ConnectFour.GameServer, lobby_registration: __MODULE__}
        )

      [{game_server, _} | _] ->
        {:ok, game_server}
    end
  end

  @doc false
  def register do
    Registry.register(ConnectFour.GameSupervisor.Lobby, :lobby, nil)
  end

  def unregister do
    Registry.unregister(ConnectFour.GameSupervisor.Lobby, :lobby)
  end
end
