defmodule Enumerable.ConnectFour.State.BoardTest do
  use ExUnit.Case, async: true
  alias ConnectFour.State.Board

  describe "count/1" do
    test "short circuit returns column count" do
      board = Board.new()

      assert {:ok, 7} == Enumerable.count(board)
    end
  end

  describe "member?/2" do
    test "returns fallback to reduce" do
      board = Board.new()

      assert {:error, Enumerable.ConnectFour.State.Board} == Enumerable.member?(board, nil)
    end
  end

  describe "slice/1" do
    test "returns fallback to reduce" do
      board = Board.new()

      assert {:error, Enumerable.ConnectFour.State.Board} == Enumerable.slice(board)
    end
  end

  describe "reduce/3" do
    test "reduces over columns transformed to lists" do
      board = Board.new(columns: 4, rows: 3)

      assert {:done,
              [
                [nil, nil, nil],
                [nil, nil, nil],
                [nil, nil, nil],
                [nil, nil, nil]
              ]} =
               Enumerable.reduce(
                 board,
                 {:cont, []},
                 fn col, acc -> {:cont, acc ++ [col]} end
               )
    end
  end
end
