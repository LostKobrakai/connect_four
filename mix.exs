defmodule ConnectFour.MixProject do
  use Mix.Project

  def project do
    [
      app: :connect_four,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ConnectFour.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:kino, "~> 0.19.0"},
      {:bandit, "~> 1.12"},
      {:websock, "~> 0.5.0"},
      {:websock_adapter, "~> 0.6.0"},
      {:mint_web_socket, "~> 1.0", only: :test}
    ]
  end
end
