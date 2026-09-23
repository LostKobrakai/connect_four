defmodule ConnectFour.GameSupervisorTest do
  use ExUnit.Case, async: false
  # How do do this async:
  # https://andrealeopardi.com/posts/async-tests-in-elixir/

  alias ConnectFour.GameServer
  alias ConnectFour.GameSupervisor

  setup do
    on_exit(fn ->
      for {_, pid, _, _} when is_pid(pid) <-
            DynamicSupervisor.which_children(GameSupervisor.Dynamic) do
        DynamicSupervisor.terminate_child(GameSupervisor.Dynamic, pid)
      end
    end)
  end

  describe "started with application" do
    test "works" do
      if :connect_four in Application.started_applications() do
        assert pid = Process.whereis(GameSupervisor)
        assert Process.alive?(pid)
      end
    end
  end

  describe "fetch_game_server/1" do
    test "starts a new game server if none is running" do
      %{active: 0} = DynamicSupervisor.count_children(GameSupervisor.Dynamic)

      assert {:ok, pid} = GameSupervisor.fetch_game_server()
      assert is_pid(pid)
    end

    test "no new game servers are started while there are non-full ones" do
      %{active: 0} = DynamicSupervisor.count_children(GameSupervisor.Dynamic)

      {:ok, pid} = GameSupervisor.fetch_game_server()
      assert {:ok, ^pid} = GameSupervisor.fetch_game_server()
    end

    test "new game servers are started even when full game servers are running" do
      %{active: 0} = DynamicSupervisor.count_children(GameSupervisor.Dynamic)

      {:ok, pid} = GameSupervisor.fetch_game_server()
      :ok = GameServer.join(pid, "Benjamin")
      :ok = GameServer.join(pid, "Bruce")

      assert {:ok, pid_new} = GameSupervisor.fetch_game_server()
      assert pid != pid_new
    end
  end
end
