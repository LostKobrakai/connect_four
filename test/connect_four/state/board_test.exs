defmodule ConnectFour.State.BoardTest do
  use ExUnit.Case, async: true
  alias ConnectFour.State.Board

  describe "new/1" do
    test "default size" do
      assert %Board{columns: 7, rows: 6} = Board.new()
    end

    test "custom size" do
      assert %Board{columns: 9, rows: 8} = Board.new(columns: 9, rows: 8)
    end

    test "default streak_length" do
      assert %Board{streak_length: 4} = Board.new()
    end

    test "custom streak_length" do
      assert %Board{streak_length: 3} = Board.new(streak_length: 3)
    end

    test "starts with empty state of board" do
      assert %Board{state: state} = Board.new()

      assert {
               {nil, nil, nil, nil, nil, nil},
               {nil, nil, nil, nil, nil, nil},
               {nil, nil, nil, nil, nil, nil},
               {nil, nil, nil, nil, nil, nil},
               {nil, nil, nil, nil, nil, nil},
               {nil, nil, nil, nil, nil, nil},
               {nil, nil, nil, nil, nil, nil}
             } = state
    end

    test "starts with empty state of board for custom size" do
      assert %Board{state: state} = Board.new(columns: 5, rows: 4)

      assert {
               {nil, nil, nil, nil},
               {nil, nil, nil, nil},
               {nil, nil, nil, nil},
               {nil, nil, nil, nil},
               {nil, nil, nil, nil}
             } = state
    end
  end

  describe "drop_disc/3" do
    test "successful drop" do
      board = Board.new(columns: 5, rows: 4)

      assert {:ok, {0, 0}, %Board{state: state}} = Board.drop_disc(board, 0, 0)

      assert {
               {0, nil, nil, nil},
               {nil, nil, nil, nil},
               {nil, nil, nil, nil},
               {nil, nil, nil, nil},
               {nil, nil, nil, nil}
             } = state
    end

    test "multiple drops on a column" do
      board = Board.new(columns: 5, rows: 4)

      {:ok, {0, 0}, board} = Board.drop_disc(board, 0, 0)
      {:ok, {0, 1}, board} = Board.drop_disc(board, 0, 1)
      assert {:ok, {0, 2}, %Board{state: state}} = Board.drop_disc(board, 0, 0)

      assert {
               {0, 1, 0, nil},
               {nil, nil, nil, nil},
               {nil, nil, nil, nil},
               {nil, nil, nil, nil},
               {nil, nil, nil, nil}
             } = state
    end

    test "multiple drops on a row" do
      board = Board.new(columns: 5, rows: 4)

      {:ok, {0, 0}, board} = Board.drop_disc(board, 0, 0)
      {:ok, {1, 0}, board} = Board.drop_disc(board, 1, 1)
      assert {:ok, {2, 0}, %Board{state: state}} = Board.drop_disc(board, 2, 0)

      assert {
               {0, nil, nil, nil},
               {1, nil, nil, nil},
               {0, nil, nil, nil},
               {nil, nil, nil, nil},
               {nil, nil, nil, nil}
             } = state
    end

    test "error when exceeding column size" do
      board = Board.new(columns: 5, rows: 4)

      {:ok, {0, 0}, board} = Board.drop_disc(board, 0, 0)
      {:ok, {0, 1}, board} = Board.drop_disc(board, 0, 1)
      {:ok, {0, 2}, board} = Board.drop_disc(board, 0, 0)
      {:ok, {0, 3}, board} = Board.drop_disc(board, 0, 1)
      assert {:error, :column_full, ^board} = Board.drop_disc(board, 0, 0)
    end
  end

  describe "won?/3" do
    test "detect no win without enough disk on the board" do
      board = Board.new()

      {:ok, coordinate, board} = Board.drop_disc(board, 0, 0)

      refute Board.won?(board, coordinate, 0)
    end

    test "detect no win when not in a column" do
      board = Board.new()

      board =
        apply_moves(board, [
          %{player: 0, col: 0},
          %{player: 1, col: 1},
          %{player: 0, col: 0},
          %{player: 1, col: 2},
          %{player: 0, col: 0},
          %{player: 1, col: 3}
        ])

      {:ok, coordinate, board} = Board.drop_disc(board, 1, 0)

      refute Board.won?(board, coordinate, 0)
    end

    test "detect no win when not in a row" do
      board = Board.new()

      board =
        apply_moves(board, [
          %{player: 0, col: 0},
          %{player: 1, col: 6},
          %{player: 0, col: 1},
          %{player: 1, col: 6},
          %{player: 0, col: 2},
          %{player: 1, col: 6}
        ])

      {:ok, coordinate, board} = Board.drop_disc(board, 0, 0)

      refute Board.won?(board, coordinate, 0)
    end

    test "detect a win with a streak in a column" do
      board = Board.new()

      board =
        apply_moves(board, [
          %{player: 0, col: 0},
          %{player: 1, col: 1},
          %{player: 0, col: 0},
          %{player: 1, col: 2},
          %{player: 0, col: 0},
          %{player: 1, col: 3}
        ])

      {:ok, coordinate, board} = Board.drop_disc(board, 0, 0)

      assert Board.won?(board, coordinate, 0)
    end

    test "detect a win with a streak in a row" do
      board = Board.new()

      board =
        apply_moves(board, [
          %{player: 0, col: 0},
          %{player: 1, col: 6},
          %{player: 0, col: 1},
          %{player: 1, col: 6},
          %{player: 0, col: 2},
          %{player: 1, col: 6}
        ])

      {:ok, coordinate, board} = Board.drop_disc(board, 3, 0)

      assert Board.won?(board, coordinate, 0)
    end

    test "detect a win with a streak on a raising diagonal" do
      board = Board.new()

      board =
        apply_moves(board, [
          %{player: 0, col: 0},
          %{player: 1, col: 1},
          %{player: 0, col: 1},
          %{player: 1, col: 2},
          %{player: 0, col: 2},
          %{player: 1, col: 3},
          %{player: 0, col: 2},
          %{player: 1, col: 3},
          %{player: 0, col: 3},
          %{player: 1, col: 4}
        ])

      {:ok, coordinate, board} = Board.drop_disc(board, 3, 0)

      assert Board.won?(board, coordinate, 0)
    end

    test "detect a win with a streak on a falling diagonal" do
      board = Board.new()

      board =
        apply_moves(board, [
          %{player: 0, col: 6},
          %{player: 1, col: 5},
          %{player: 0, col: 5},
          %{player: 1, col: 4},
          %{player: 0, col: 4},
          %{player: 1, col: 3},
          %{player: 0, col: 4},
          %{player: 1, col: 3},
          %{player: 0, col: 3},
          %{player: 1, col: 5}
        ])

      {:ok, coordinate, board} = Board.drop_disc(board, 3, 0)

      assert Board.won?(board, coordinate, 0)
    end
  end

  defp apply_moves(board, moves) do
    Enum.reduce(moves, board, fn %{player: player_index, col: column_index}, board ->
      {:ok, _, board} = Board.drop_disc(board, column_index, player_index)
      board
    end)
  end
end
