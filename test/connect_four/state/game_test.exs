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

      assert {:ok, %Game{} = game} = Game.add_player(game, "Bruce")

      assert %{"Bruce" => 0} = game.players
      assert [1] == game.player_indexes
      assert :setup == game.state
    end

    test "moves to first turn once all players are filled", %{board: board} do
      game = Game.new(board)
      {:ok, game} = Game.add_player(game, "Bruce")

      assert {:ok, %Game{} = game} = Game.add_player(game, "Benjamin")

      assert %{"Bruce" => 0, "Benjamin" => 1} = game.players
      assert [] == game.player_indexes
      assert {:turn, 0} == game.state
    end

    test "cannot add more player than allowed", %{board: board} do
      game = Game.new(board)
      {:ok, game} = Game.add_player(game, "Bruce")
      {:ok, game} = Game.add_player(game, "Benjamin")

      assert {:error, :started} = Game.add_player(game, "lars")
    end
  end

  describe "drop_disc/3" do
    setup do
      board = Board.new(columns: 5, rows: 4)
      game = Game.new(board)
      {:ok, game} = Game.add_player(game, "Bruce")
      {:ok, game} = Game.add_player(game, "Benjamin")
      %{game: game}
    end

    test "player can drop a piece on their turn", %{game: game} do
      assert {:continue, %Game{} = game} = Game.drop_disc(game, "Bruce", 1)
      assert {:turn, 1} == game.state
    end

    test "player can not drop a piece on another players turn", %{game: game} do
      assert {:error, :not_player_turn} = Game.drop_disc(game, "Benjamin", 0)
    end

    test "player can win with their turn", %{game: game} do
      game =
        with {:continue, game} <- Game.drop_disc(game, "Bruce", 0),
             {:continue, game} <- Game.drop_disc(game, "Benjamin", 4),
             {:continue, game} <- Game.drop_disc(game, "Bruce", 0),
             {:continue, game} <- Game.drop_disc(game, "Benjamin", 4),
             {:continue, game} <- Game.drop_disc(game, "Bruce", 0),
             {:continue, game} <- Game.drop_disc(game, "Benjamin", 4) do
          game
        end

      assert {:won, "Bruce", %Game{} = game} = Game.drop_disc(game, "Bruce", 0)
      assert {:won, 0} == game.state
    end

    test "a game can end in a draw", %{game: game} do
      moves =
        for half_col <- 0..9//2,
            a = rem(half_col, 5),
            b = rem(half_col + 1, 5),
            move <- [
              %{player: "Bruce", col: a},
              %{player: "Benjamin", col: b},
              %{player: "Bruce", col: a},
              %{player: "Benjamin", col: b}
            ] do
          move
        end

      {last_move, moves} = List.pop_at(moves, -1)

      game =
        Enum.reduce(moves, game, fn move, game ->
          {:continue, game} = Game.drop_disc(game, move.player, move.col)
          game
        end)

      assert {:draw, %Game{} = game} = Game.drop_disc(game, last_move.player, last_move.col)
      assert :draw == game.state
    end
  end
end
