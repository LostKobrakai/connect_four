defmodule ConnectFour.State.Game do
  alias ConnectFour.State.Board

  defstruct [:state, :board, players: %{}, player_indexes: [0, 1]]

  def new(%Board{} = board) do
    %__MODULE__{board: board, state: :setup}
  end

  def add_player(%__MODULE__{player_indexes: []}, _name) do
    {:error, :started}
  end

  def add_player(%__MODULE__{} = game, name) do
    [player_index | rest] = game.player_indexes
    players = Map.put(game.players, name, player_index)

    state =
      case rest do
        [] -> {:turn, 0}
        _ -> game.state
      end

    {:ok, %__MODULE__{game | state: state, player_indexes: rest, players: players}}
  end

  def players_turn?(%__MODULE__{} = game, name) do
    with {:ok, player_index} <- player_index(game, name),
         :ok <- players_turn(game, player_index) do
      true
    else
      _ -> false
    end
  end

  def drop_disc(%__MODULE__{} = game, name, column_index) do
    with {:ok, player_index} <- player_index(game, name),
         :ok <- players_turn(game, player_index),
         {:ok, coordinate, %__MODULE__{} = game} <-
           drop_on_board(game, column_index, player_index) do
      if Board.won?(game.board, coordinate, player_index) do
        {:won, name, %__MODULE__{game | state: {:won, player_index}}}
      else
        next_player_index = rem(player_index + 1, map_size(game.players))
        {:continue, %__MODULE__{game | state: {:turn, next_player_index}}}
      end
    end
  end

  defp player_index(%__MODULE__{} = game, name) do
    case Map.fetch(game.players, name) do
      {:ok, player_index} -> {:ok, player_index}
      :error -> {:error, :invalid_player}
    end
  end

  defp players_turn(%__MODULE__{} = game, player_index) do
    case game.state do
      {:turn, ^player_index} -> :ok
      _ -> {:error, :not_player_turn}
    end
  end

  defp drop_on_board(%__MODULE__{board: board} = game, column_index, player_index) do
    case Board.drop_disc(board, column_index, player_index) do
      {:ok, coordinate, board} -> {:ok, coordinate, %__MODULE__{game | board: board}}
      {:error, :column_full, _} -> {:error, :column_full}
    end
  end
end
