defmodule ConnectFour.State.GameTest do
  use ExUnit.Case, async: true
  alias ConnectFour.State.Board
  alias ConnectFour.State.Game

  describe "new/1" do
    setup do
      %{board: Board.new(columns: 5, rows: 4)}
    end

    test "built with a board" do
      board = Board.new(columns: 5, rows: 4)
      assert %Game{board: ^board, player_indexes: [0, 1]} = Game.new(board)
    end

    test "starts in setup state with no players", %{board: board} do
      assert %Game{state: :setup, players: %{}} = Game.new(board)
    end
  end

  describe "add_player/2" do
    setup do
      %{board: Board.new(columns: 5, rows: 4)}
    end

    test "players can be added", %{board: board} do
      game = Game.new(board)

      assert {:ok, %Game{} = game} = Game.add_player(game, "bruce")

      assert %{"bruce" => 0} = game.players
      assert [1] == game.player_indexes
      assert :setup == game.state
    end

    test "moves to first turn once all players are filled", %{board: board} do
      game = Game.new(board)
      {:ok, game} = Game.add_player(game, "bruce")

      assert {:ok, %Game{} = game} = Game.add_player(game, "benjamin")

      assert %{"bruce" => 0, "benjamin" => 1} = game.players
      assert [] == game.player_indexes
      assert {:turn, 0} == game.state
    end

    test "cannot add more player than allowed", %{board: board} do
      game = Game.new(board)
      {:ok, game} = Game.add_player(game, "bruce")
      {:ok, game} = Game.add_player(game, "benjamin")

      assert {:error, :started} = Game.add_player(game, "lars")
    end
  end

  #
  describe "drop_disc/3" do
    setup do
      board = Board.new(columns: 5, rows: 4)
      game = Game.new(board)
      {:ok, game} = Game.add_player(game, "bruce")
      {:ok, game} = Game.add_player(game, "benjamin")
      %{game: game}
    end

    test "player can drop a piece on their turn", %{game: game} do
      assert {:continue, %Game{} = game} = Game.drop_disc(game, "bruce", 1)
      assert {:turn, 1} == game.state

      assert {
               {nil, nil, nil, nil},
               {0, nil, nil, nil},
               {nil, nil, nil, nil},
               {nil, nil, nil, nil},
               {nil, nil, nil, nil}
             } = game.board.state
    end

    test "player can not drop a piece on another players turn", %{game: game} do
      assert {:error, :not_player_turn} = Game.drop_disc(game, "benjamin", 0)
    end

    test "player can win with their turn", %{game: game} do
      game =
        with {:continue, game} <- Game.drop_disc(game, "bruce", 0),
             {:continue, game} <- Game.drop_disc(game, "benjamin", 4),
             {:continue, game} <- Game.drop_disc(game, "bruce", 0),
             {:continue, game} <- Game.drop_disc(game, "benjamin", 4),
             {:continue, game} <- Game.drop_disc(game, "bruce", 0),
             {:continue, game} <- Game.drop_disc(game, "benjamin", 4) do
          game
        end

      assert {:won, "bruce", %Game{} = game} = Game.drop_disc(game, "bruce", 0)
      assert {:won, 0} == game.state
    end
  end
end
