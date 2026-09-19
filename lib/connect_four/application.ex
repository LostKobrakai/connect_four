defmodule ConnectFour.Application do
  use Application

  def start(_type, _args) do
    children = [
      ConnectFour.GameSupervisor,
      ConnectFour.GameClient.Web
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
