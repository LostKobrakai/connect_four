defmodule ConnectFour.Renderer.AnsiTest do
  use ExUnit.Case, async: true
  alias ConnectFour.State.Board
  alias ConnectFour.State.Game
  alias ConnectFour.Renderer.Ansi

  describe "grid/1" do
    test "renders an empty board as gray circles" do
      board = Board.new(columns: 3, rows: 2)

      assert Ansi.grid(board) == [
               [cell(:light_black), " ", cell(:light_black), " ", cell(:light_black)],
               [cell(:light_black), " ", cell(:light_black), " ", cell(:light_black)]
             ]
    end

    test "colors cells by player index and leaves untouched cells gray" do
      board = Board.new(columns: 3, rows: 2)
      {:ok, _, board} = Board.drop_disc(board, 0, 0)
      {:ok, _, board} = Board.drop_disc(board, 1, 1)

      assert Ansi.grid(board) == [
               [cell(:light_black), " ", cell(:light_black), " ", cell(:light_black)],
               [cell(:yellow), " ", cell(:red), " ", cell(:light_black)]
             ]
    end

    test "renders rows top to bottom, so a stacked column reads bottom-up" do
      board = Board.new(columns: 1, rows: 3)
      {:ok, _, board} = Board.drop_disc(board, 0, 0)
      {:ok, _, board} = Board.drop_disc(board, 0, 1)

      assert Ansi.grid(board) == [
               [cell(:light_black)],
               [cell(:red)],
               [cell(:yellow)]
             ]
    end
  end

  describe "layout/1" do
    test "renders for unstarted game" do
      board = Board.new(columns: 2, rows: 4)
      game = Game.new(board)

      assert Ansi.layout(game) == [
               [cell(:light_black), " ", cell(:light_black) | player(:yellow, :waiting)],
               [cell(:light_black), " ", cell(:light_black) | player(:red, :waiting)],
               [cell(:light_black), " ", cell(:light_black)],
               [cell(:light_black), " ", cell(:light_black)]
             ]
    end

    test "renders incomplete lobby" do
      board = Board.new(columns: 2, rows: 4)
      game = Game.new(board)
      {:ok, game} = Game.add_player(game, "Benjamin")

      assert Ansi.layout(game) == [
               [cell(:light_black), " ", cell(:light_black) | player(:yellow, "Benjamin")],
               [cell(:light_black), " ", cell(:light_black) | player(:red, :waiting)],
               [cell(:light_black), " ", cell(:light_black)],
               [cell(:light_black), " ", cell(:light_black)]
             ]
    end

    test "renders stated game" do
      board = Board.new(columns: 2, rows: 4)
      game = Game.new(board)
      {:ok, game} = Game.add_player(game, "Benjamin")
      {:ok, game} = Game.add_player(game, "Bruce")

      assert Ansi.layout(game) == [
               [
                 cell(:light_black),
                 " ",
                 cell(:light_black) | player(:yellow, {:turn, "Benjamin"})
               ],
               [cell(:light_black), " ", cell(:light_black) | player(:red, "Bruce")],
               [cell(:light_black), " ", cell(:light_black)],
               [cell(:light_black), " ", cell(:light_black)]
             ]
    end

    test "renders second player turn" do
      board = Board.new(columns: 2, rows: 4)
      game = Game.new(board)
      {:ok, game} = Game.add_player(game, "Benjamin")
      {:ok, game} = Game.add_player(game, "Bruce")
      {:continue, game} = Game.drop_disc(game, "Benjamin", 0)
      {:continue, game} = Game.drop_disc(game, "Bruce", 1)
      {:continue, game} = Game.drop_disc(game, "Benjamin", 0)

      assert Ansi.layout(game) == [
               [cell(:light_black), " ", cell(:light_black) | player(:yellow, "Benjamin")],
               [cell(:light_black), " ", cell(:light_black) | player(:red, {:turn, "Bruce"})],
               [cell(:yellow), " ", cell(:light_black)],
               [cell(:yellow), " ", cell(:red)]
             ]
    end

    test "renders won game" do
      board = Board.new(columns: 2, rows: 4)
      game = Game.new(board)
      {:ok, game} = Game.add_player(game, "Benjamin")
      {:ok, game} = Game.add_player(game, "Bruce")
      {:continue, game} = Game.drop_disc(game, "Benjamin", 0)
      {:continue, game} = Game.drop_disc(game, "Bruce", 1)
      {:continue, game} = Game.drop_disc(game, "Benjamin", 0)
      {:continue, game} = Game.drop_disc(game, "Bruce", 1)
      {:continue, game} = Game.drop_disc(game, "Benjamin", 0)
      {:continue, game} = Game.drop_disc(game, "Bruce", 1)
      {:won, _, game} = Game.drop_disc(game, "Benjamin", 0)

      assert Ansi.layout(game) == [
               [cell(:yellow), " ", cell(:light_black) | player(:yellow, {:won, "Benjamin"})],
               [cell(:yellow), " ", cell(:red) | player(:red, "Bruce")],
               [cell(:yellow), " ", cell(:red)],
               [cell(:yellow), " ", cell(:red)]
             ]
    end
  end

  describe "buttons/2" do
    test "creates buttons for a board" do
      board = Board.new(columns: 2, rows: 4)

      assert %Kino.Layout{
               items: [
                 %Kino.Control{},
                 %Kino.Control{}
               ]
             } = Ansi.buttons(board)
    end

    test "can provide a callback getting button and column number handed" do
      board = Board.new(columns: 2, rows: 4)

      Ansi.buttons(board, fn control, number ->
        assert %Kino.Control{} = control
        assert is_integer(number)
        assert number > 0
      end)
    end
  end

  describe "render/1" do
    test "formats the grid through IO.ANSI.format/1" do
      board = Board.new(columns: 1, rows: 1)

      assert Ansi.render(board) ==
               board |> Ansi.grid() |> Enum.intersperse("\n") |> IO.ANSI.format()
    end

    test "formats the layout through IO.ANSI.format/1" do
      board = Board.new(columns: 1, rows: 1)
      game = Game.new(board)

      assert Ansi.render(game) ==
               game |> Ansi.layout() |> Enum.intersperse("\n") |> IO.ANSI.format()
    end
  end

  defp cell(:light_black), do: [:light_black, "○", :reset]
  defp cell(color), do: [color, "◉", :reset]

  defp player(color, :waiting) do
    ["   ", [color, "●", :reset], " ", [:italic, "waiting for player", :reset]]
  end

  defp player(color, {:turn, name}) do
    ["   ", [color, "●", :reset], " ", [name, " ", "<"]]
  end

  defp player(color, {:won, name}) do
    ["   ", [color, "●", :reset], " ", [name, " ", "👑"]]
  end

  defp player(color, name) do
    ["   ", [color, "●", :reset], " ", name]
  end
end
