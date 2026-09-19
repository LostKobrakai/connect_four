defmodule ConnectFour.GameClient.Web do
  @moduledoc """
  Web based game client.

  Only started with explicitly passed port or one provided via `PORT` environment
  variable.
  """
  alias ConnectFour.GameClient.Web.Router

  # More info on child_specs:
  # https://elixir.hexdocs.pm/Supervisor.html#module-child_spec-1-function
  def child_spec(init_arg) do
    port = Keyword.get_lazy(init_arg, :port, fn -> System.get_env("PORT") end)

    if port do
      Bandit.child_spec(plug: Router, port: 4000)
    else
      %{id: __MODULE__, start: {Function, :identity, [:ignore]}}
    end
  end
end
