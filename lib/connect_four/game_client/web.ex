defmodule ConnectFour.GameClient.Web do
  @moduledoc """
  Web based game client.

  Only started with explicitly passed port or one provided via `PORT` environment
  variable. Binds to `:loopback` unless `ip: :any` is passed or the `IP` environment
  variable is set to `"any"`.
  """
  alias ConnectFour.GameClient.Web.Router

  # More info on child_specs:
  # https://elixir.hexdocs.pm/Supervisor.html#module-child_spec-1-function
  def child_spec(init_arg) do
    ip =
      Keyword.get_lazy(init_arg, :ip, fn ->
        if System.get_env("IP") == "any", do: :any, else: :loopback
      end)

    port = Keyword.get_lazy(init_arg, :port, fn -> System.get_env("PORT") end)

    if port do
      Bandit.child_spec(plug: Router, port: port, ip: ip)
    else
      %{id: __MODULE__, start: {Function, :identity, [:ignore]}}
    end
  end
end
