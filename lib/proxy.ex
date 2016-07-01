defmodule Proxy do
  use Plug.Builder
  import Plug.Conn

  plug :dispatch

  @url "http://localhost:4000"

  def start(_argv) do
    port = 4001
    IO.puts "Running Proxy with Cowboy on http://localhost:#{port}"
    Plug.Adapters.Cowboy.http __MODULE__, [], port: port
    :timer.sleep(:infinity)
  end

  def dispatch(conn, _opts) do
    method = conn.method
    base_path = Application.get_env(:proxy, :base_path)
    url = base_path <> conn.request_path
    {:ok, body, _} = read_body(conn, [])
    headers = [{"Content-Type", "application/json"}]
    query_params = fetch_query_params(conn).query_params
    params = [params: query_params]

    {:ok, response} = HTTPoison.request(method, url, body, headers, params)

    conn
    |> put_resp_header("content-type", "application/json; charset=utf-8")
    |> send_resp(200, response.body)
  end
end
