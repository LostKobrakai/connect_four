defmodule ConnectFour.Test.WebClient do
  @moduledoc """
  A minimal Mint/Mint.WebSocket-based HTTP and WebSocket client.

  Consider `:req` for plain http testing!
  """

  require Mint.HTTP

  def get(port, path) do
    {:ok, conn} = Mint.HTTP.connect(:http, "localhost", port)
    {:ok, conn, ref} = Mint.HTTP.request(conn, "GET", path, [], nil)

    {conn, responses} = await_http_responses(conn, ref, [])
    ExUnit.Callbacks.on_exit(fn -> Mint.HTTP.close(conn) end)

    status =
      Enum.find_value(responses, fn
        {:status, ^ref, status} -> status
        _ -> nil
      end)

    body = for {:data, ^ref, data} <- responses, into: "", do: data

    {status, body}
  end

  def connect(port, name) do
    {:ok, conn} = Mint.HTTP.connect(:http, "localhost", port)
    {:ok, conn, ref} = Mint.WebSocket.upgrade(:ws, conn, "/ws?name=#{name}", [])

    {conn, responses} = await_http_responses(conn, ref, [])

    status =
      Enum.find_value(responses, fn
        {:status, ^ref, status} -> status
        _ -> nil
      end)

    headers =
      Enum.find_value(responses, fn
        {:headers, ^ref, headers} -> headers
        _ -> nil
      end)

    {:ok, conn, websocket} = Mint.WebSocket.new(conn, ref, status, headers)

    ExUnit.Callbacks.on_exit(fn -> Mint.HTTP.close(conn) end)

    %{conn: conn, ref: ref, websocket: websocket}
  end

  def send_json(%{conn: conn, ref: ref, websocket: websocket} = client, data) do
    {:ok, websocket, frame} = Mint.WebSocket.encode(websocket, {:text, JSON.encode!(data)})
    {:ok, conn} = Mint.WebSocket.stream_request_body(conn, ref, frame)

    %{client | conn: conn, websocket: websocket}
  end

  def recv_json(%{conn: conn, ref: ref, websocket: websocket} = client) do
    {conn, websocket, [{:text, text}]} = await_frame(conn, ref, websocket)

    {%{client | conn: conn, websocket: websocket}, JSON.decode!(text)}
  end

  defp await_http_responses(conn, ref, acc) do
    message =
      receive do
        message when Mint.HTTP.is_connection_message(conn, message) -> message
      end

    {:ok, conn, responses} = Mint.WebSocket.stream(conn, message)
    acc = acc ++ responses

    if Enum.any?(responses, &match?({:done, ^ref}, &1)) do
      {conn, acc}
    else
      await_http_responses(conn, ref, acc)
    end
  end

  defp await_frame(conn, ref, websocket) do
    message =
      receive do
        message when Mint.HTTP.is_connection_message(conn, message) -> message
      end

    {:ok, conn, responses} = Mint.WebSocket.stream(conn, message)
    data = for {:data, ^ref, data} <- responses, into: <<>>, do: data

    case data do
      <<>> ->
        await_frame(conn, ref, websocket)

      data ->
        {:ok, websocket, frames} = Mint.WebSocket.decode(websocket, data)
        {conn, websocket, frames}
    end
  end
end
