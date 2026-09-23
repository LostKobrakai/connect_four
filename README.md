# ConnectFour

Connect Four Game for "Introducing Elixir" workshop at Goatmire 2026.

## Getting started

Install dependencies:

```sh
mix deps.get
```

Run the test suite:

```sh
mix test
```

## Running from Livebook

`ConnectFour.GameClient.Livebook` renders the board with `Kino` and wires up
clickable column buttons, for use inside a Livebook notebook having pulled this
package in using `Mix.install/2`.

The web client can be started manually using `Kino.start_child()` within a
Livebook. Since `Mix.install/2` does not start the app with a `PORT`
configured, pass the port explicitly to `ConnectFour.GameClient.Web`'s child
spec so it stays tied to the cell's lifecycle:

```elixir
Kino.start_child({ConnectFour.GameClient.Web, port: 4000})
```

### Expose web client

By default the server binds to `:loopback`, so it's only reachable from the
machine Livebook is running on. Pass `ip: :any` to bind on all network
interfaces instead, so other devices on the same network (e.g. workshop
participants' laptops) can connect too:

```elixir
Kino.start_child({ConnectFour.GameClient.Web, ip: :any, port: 4000})
```

## Running from IEx

The web client (a Bandit HTTP/WebSocket server serving `priv/static/`) only
starts if a port is configured, either explicitly or via the `PORT`
environment variable:

```sh
PORT=4000 iex -S mix
```

Then open <http://localhost:4000> in a browser. The page connects to
`/ws?name=<player name>` over WebSockets and joins (or creates) the single
lobby game managed by `ConnectFour.GameSupervisor`.

By default the server binds to `:loopback`, so it's only reachable from the
machine it's running on. Set `IP=any` to bind on all network interfaces
instead, so other devices on the same network can connect too:

```sh
PORT=4000 IP=any iex -S mix
```

### Manual client

Without a web client, you can drive a game directly from an `iex -S mix`
session:

```elixir
{:ok, server} = ConnectFour.GameSupervisor.fetch_game_server()
:ok = ConnectFour.GameServer.join(server, "alice")
:ok = ConnectFour.GameServer.join(server, "bob")
:ok = ConnectFour.GameServer.drop_disc(server, "alice", 0)
ConnectFour.GameServer.game_state(server)
```
