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
    cookies =  cookies(conn)
    opts = Keyword.merge(params, cookies)

    name = :crypto.hash(:sha256, [method, url, body, "#{inspect headers}", "#{inspect params}"]) |> Base.encode16

    {resp_headers, resp_body} = if File.exists?("cache/" <> name) do
      IO.puts "From cache: #{name}"
      {nil, File.read!("cache/" <> name) |> String.trim()}
    else
      IO.puts "Real call: #{url}"
      {response_headers, response_body} = call_service(method, url, body, headers, opts)
      File.write("cache/" <> name, response_body)
      {response_headers, response_body}
    end

    [hackney: [cookie: [resp_cook]]] = cookies

    conn = if response_headers != nil do
      c = Enum.filter(response_headers, fn({k, v}) -> k == "Set-Cookie" end) |>
          Enum.map(fn({k,v}) -> Plug.Conn.Cookies.decode(v) end)

      if c != [] do
        [c1 | _] = c
        conn
        |> put_resp_cookie("session", c1["session"])
      else
        conn
      end
    else
      conn
    end

    conn
    |> put_resp_header("content-type", "application/json; charset=utf-8")
    |> send_resp(200, resp_body)
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

  defp cookies(conn) do
    conn = fetch_cookies(conn)
    cookies = Enum.reduce(conn.cookies, "", fn({k, v}, acc) -> acc <> k <> "=" <> v <> "; " end)
    [hackney: [cookie: [ cookies ]]]
  end

  defp params(conn) do
    query_params = fetch_query_params(conn).query_params
    [params: query_params]
  end

  defp call_service(method, url, body, headers, params) do
    {:ok, response} = HTTPoison.request(method, url, body, headers, params)
    {response.headers, response.body}
  end
end
