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
    url = url(conn)
    body = body(conn)
    headers = headers()
    params = params(conn)

    name = :crypto.hash(:sha256, [method, url, body, "#{inspect headers}", "#{inspect params}"]) |> Base.encode16

    response_body = if File.exists?("cache/" <> name) do
      IO.puts "From cache"
      File.read!("cache/" <> name)
    else
      IO.puts "Real call"
      response_body = call_service(method, url, body, headers, params)
      File.write("cache/" <> name, response_body)
      response_body
    end

    conn
    |> put_resp_header("content-type", "application/json; charset=utf-8")
    |> send_resp(200, response_body)
  end

  defp url(conn) do
    base_path = Application.get_env(:proxy, :base_path)
    base_path <> conn.request_path
  end

  defp body(conn) do
    {:ok, body, _} = read_body(conn, [])
    body
  end

  defp headers() do
    [{"Content-Type", "application/json"}]
  end

  defp params(conn) do
    query_params = fetch_query_params(conn).query_params
    [params: query_params]
  end

  defp call_service(method, url, body, headers, params) do
    {:ok, response} = HTTPoison.request(method, url, body, headers, params)
    response.body
  end
end
