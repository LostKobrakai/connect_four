defmodule ConnectFour.GameClient.WebTest do
  use ExUnit.Case, async: false

  alias ConnectFour.GameClient.Web
  alias ConnectFour.GameSupervisor
  alias ConnectFour.Test.WebClient

  @moduletag capture_log: true

  setup do
    bandit = start_supervised!({Web, port: 0})
    {:ok, {_ip, port}} = ThousandIsland.listener_info(bandit)

    on_exit(fn ->
      for {_, pid, _, _} when is_pid(pid) <-
            DynamicSupervisor.which_children(GameSupervisor.Dynamic) do
        DynamicSupervisor.terminate_child(GameSupervisor.Dynamic, pid)
      end
    end)

    %{port: port}
  end

  describe "integration" do
    test "GET /: html is accessible", %{port: port} do
      assert {200, body} = WebClient.get(port, "/")
      assert body =~ "<title>Connect Four</title>"
    end

    test "GET /ws: two players join and play a move over real WebSocket frames", %{port: port} do
      alice = WebClient.connect(port, "Alice")

      assert {alice, %{"game_state" => game_state}} = WebClient.recv_json(alice)
      assert %{"state" => "setup", "players" => ["Alice", nil]} = game_state

      bruce = WebClient.connect(port, "Bruce")

      assert {bruce, %{"players_turn" => false, "game_state" => game_state}} =
               WebClient.recv_json(bruce)

      assert %{"state" => ["turn", 0], "players" => ["Alice", "Bruce"]} = game_state

      assert {alice, %{"players_turn" => true, "game_state" => game_state}} =
               WebClient.recv_json(alice)

      assert %{"state" => ["turn", 0], "players" => ["Alice", "Bruce"]} = game_state

      alice = WebClient.send_json(alice, %{type: "drop", index: 0})

      assert {_bruce, %{"players_turn" => true, "game_state" => game_state}} =
               WebClient.recv_json(bruce)

      assert %{"state" => ["turn", 1], "board" => %{"state" => %{"0" => 0}}} = game_state

      assert {alice, %{"players_turn" => false, "game_state" => game_state}} =
               WebClient.recv_json(alice)

      assert %{"state" => ["turn", 1], "board" => %{"state" => %{"0" => 0}}} = game_state

      alice = WebClient.send_json(alice, %{type: "drop", index: 0})
      assert {_alice, %{"type" => "error"}} = WebClient.recv_json(alice)
    end
  end
end
