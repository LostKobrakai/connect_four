defmodule ConnectFour.GameClient.Web.Router do
  use Plug.Router
  alias ConnectFour.GameClient.Web.WebsocketConnection

  plug :match
  plug :rewrite_index
  plug Plug.Static, at: "/", from: {:connect_four, "priv/static"}
  plug :fetch_query_params
  plug :dispatch

  get "/" do
    send_resp(conn, 404, "")
  end

  get "/ws" do
    %{"name" => name} = conn.params
    WebSockAdapter.upgrade(conn, WebsocketConnection, [name: name], [])
  end

  get _ do
    send_resp(conn, 404, "")
  end

  defp rewrite_index(conn, _opts) do
    if Plug.Router.match_path(conn) == "/" do
      %{conn | path_info: ["index.html"]}
    else
      conn
    end
  end
end
