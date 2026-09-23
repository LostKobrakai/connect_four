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

      expected = for x <- 0..6, y <- 0..5, into: MapSet.new(), do: {x, y}
      assert Map.has_key?(state, {6, 5})
      refute Map.has_key?(state, {5, 6})
      assert MapSet.equal?(state |> Map.keys() |> MapSet.new(), expected)
    end

    test "starts with empty state of board for custom size" do
      assert %Board{state: state} = Board.new(columns: 5, rows: 4)

      expected = for x <- 0..4, y <- 0..3, into: MapSet.new(), do: {x, y}
      assert Map.has_key?(state, {4, 3})
      refute Map.has_key?(state, {3, 4})
      assert MapSet.equal?(state |> Map.keys() |> MapSet.new(), expected)
    end
  end

  describe "drop_disc/3" do
    test "successful drop" do
      board = Board.new(columns: 5, rows: 4)

      assert {:ok, {0, 0}, %Board{state: state}} = Board.drop_disc(board, 0, 0)

      assert %{{0, 0} => 0} == drop_empty_cells(state)
    end

    test "multiple drops on a column" do
      board = Board.new(columns: 5, rows: 4)

      {:ok, {0, 0}, board} = Board.drop_disc(board, 0, 0)
      {:ok, {0, 1}, board} = Board.drop_disc(board, 0, 1)
      assert {:ok, {0, 2}, %Board{state: state}} = Board.drop_disc(board, 0, 0)

      assert %{
               {0, 0} => 0,
               {0, 1} => 1,
               {0, 2} => 0
             } == drop_empty_cells(state)
    end

    test "multiple drops on a row" do
      board = Board.new(columns: 5, rows: 4)

      {:ok, {0, 0}, board} = Board.drop_disc(board, 0, 0)
      {:ok, {1, 0}, board} = Board.drop_disc(board, 1, 1)
      assert {:ok, {2, 0}, %Board{state: state}} = Board.drop_disc(board, 2, 0)

      assert %{
               {0, 0} => 0,
               {1, 0} => 1,
               {2, 0} => 0
             } == drop_empty_cells(state)
    end

    test "error when exceeding column size" do
      board = Board.new(columns: 5, rows: 4)

      {:ok, {0, 0}, board} = Board.drop_disc(board, 0, 0)
      {:ok, {0, 1}, board} = Board.drop_disc(board, 0, 1)
      {:ok, {0, 2}, board} = Board.drop_disc(board, 0, 0)
      {:ok, {0, 3}, board} = Board.drop_disc(board, 0, 1)
      assert {:error, :column_full} = Board.drop_disc(board, 0, 0)
    end
  end

  describe "won_by?/3" do
    test "detect no win without enough disk on the board" do
      board = Board.new()

      {:ok, coordinate, board} = Board.drop_disc(board, 0, 0)

      refute Board.won_by?(board, coordinate, 0)
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

      refute Board.won_by?(board, coordinate, 0)
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

      refute Board.won_by?(board, coordinate, 0)
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

      assert Board.won_by?(board, coordinate, 0)
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

      assert Board.won_by?(board, coordinate, 0)
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

      assert Board.won_by?(board, coordinate, 0)
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

      assert Board.won_by?(board, coordinate, 0)
    end
  end

  describe "moves_left?/1" do
    test "not a draw" do
      board = Board.new()

      assert Board.moves_left?(board)
    end

    test "a draw" do
      board = Board.new()

      # 1010101
      # 1010101
      # 1010101
      # 0101010
      # 0101010
      # 0101010

      moves =
        for half_col <- 0..13//2,
            a = rem(half_col, 7),
            b = rem(half_col + 1, 7),
            move <- [
              %{player: 0, col: a},
              %{player: 1, col: b},
              %{player: 0, col: a},
              %{player: 1, col: b},
              %{player: 0, col: a},
              %{player: 1, col: b}
            ] do
          move
        end

      board = apply_moves(board, moves)

      refute Board.moves_left?(board)
    end
  end

  defp drop_empty_cells(state) do
    state |> Enum.filter(fn {_coords, value} -> value end) |> Map.new()
  end

  defp apply_moves(board, moves) do
    Enum.reduce(moves, board, fn %{player: player_index, col: column_index}, board ->
      {:ok, _, board} = Board.drop_disc(board, column_index, player_index)
      board
    end)
  end
end
