defmodule ConnectFour.GameServerTest do
  use ExUnit.Case, async: true
  alias ConnectFour.GameServer
  alias ConnectFour.State.Game

  describe "start_link/1" do
    test "can be successfully started" do
      assert {:ok, _} = GameServer.start_link([])
    end
  end

  describe "restart type" do
    test "does not restart" do
      {:ok, pid} = start_supervised(GameServer)
      ref = Process.monitor(pid)

      Process.exit(pid, :kill)

      assert_receive {:DOWN, ^ref, :process, _, :killed}

      assert {:error, :not_found} == stop_supervised(GameServer)
    end
  end

  describe "join/2" do
    test "a player can join a game" do
      {:ok, game} = GameServer.start_link([])

      assert :ok = GameServer.join(game, "Benjamin")
    end

    test "joined player processes recive game states" do
      {:ok, game} = GameServer.start_link([])

      :ok = GameServer.join(game, "Benjamin")

      assert_received {GameServer, %{name: "Benjamin", game_state: %Game{}}}
    end

    test "multiple player can join a game" do
      {:ok, game} = GameServer.start_link([])

      :ok = GameServer.join(game, "Benjamin")

      assert :ok = GameServer.join(game, "Bruce")

      assert_received {GameServer, %{name: "Benjamin", game_state: %Game{} = game_state}}
      assert game_state.player_indexes == [1]

      assert_received {GameServer, %{name: "Benjamin", game_state: %Game{} = game_state}}
      assert game_state.player_indexes == []
    end

    test "players can no longer join when the game has started" do
      {:ok, game} = GameServer.start_link([])

      :ok = GameServer.join(game, "Benjamin")
      :ok = GameServer.join(game, "Bruce")

      assert {:error, :started} = GameServer.join(game, "Lars")
    end

    @tag :capture_log
    test "a player going away abnormally crashes the game" do
      {:ok, game} = GameServer.start_link([])

      Process.unlink(game)
      ref = Process.monitor(game)

      Task.start(fn ->
        GameServer.join(game, "Benjamin")
        exit(:kill)
      end)

      assert_receive {:DOWN, ^ref, :process, ^game, :kill}
    end
  end

  describe "drop_disc/3" do
    test "works" do
      {:ok, game} = GameServer.start_link([])

      :ok = GameServer.join(game, "Benjamin")
      :ok = GameServer.join(game, "Bruce")

      assert :ok = GameServer.drop_disc(game, "Benjamin", 0)

      assert_received {GameServer, %{name: "Benjamin", game_state: %Game{} = game_state}}
                      when game_state.state == {:turn, 1}
    end

    test "cannot drop out of turn" do
      {:ok, game} = GameServer.start_link([])

      :ok = GameServer.join(game, "Benjamin")
      :ok = GameServer.join(game, "Bruce")

      assert {:error, :not_player_turn} = GameServer.drop_disc(game, "Bruce", 0)
    end

    test "can win a game on drop" do
      {:ok, game} = GameServer.start_link([])

      ref = Process.monitor(game)

      :ok = GameServer.join(game, "Benjamin")
      :ok = GameServer.join(game, "Bruce")
      :ok = GameServer.drop_disc(game, "Benjamin", 0)
      :ok = GameServer.drop_disc(game, "Bruce", 1)
      :ok = GameServer.drop_disc(game, "Benjamin", 0)
      :ok = GameServer.drop_disc(game, "Bruce", 1)
      :ok = GameServer.drop_disc(game, "Benjamin", 0)
      :ok = GameServer.drop_disc(game, "Bruce", 1)
      :ok = GameServer.drop_disc(game, "Benjamin", 0)

      assert_received {GameServer, %{name: "Benjamin", game_state: %Game{} = game_state}}
                      when game_state.state == {:won, 0}

      assert_receive {:DOWN, ^ref, :process, ^game, {:shutdown, :won}}

      refute Process.alive?(game)
    end
  end

  describe "game_state/3" do
    test "works" do
      {:ok, game} = GameServer.start_link([])

      :ok = GameServer.join(game, "Benjamin")
      :ok = GameServer.join(game, "Bruce")

      assert %Game{} = GameServer.game_state(game)
    end
  end
end
