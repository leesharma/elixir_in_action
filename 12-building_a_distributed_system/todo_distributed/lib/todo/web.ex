defmodule Todo.Web do
  use Plug.Router

  plug :match
  plug :dispatch

  def start_server do
    Plug.Adapters.Cowboy.http(__MODULE__, nil, port: port())
  end

  defp port do
    port = case Application.get_env(:todo, :port) do
      nil  -> raise("Todo port not specified!")
      port -> port
    end
    IO.puts "Starting web server on port #{port}."

    port
  end

  # curl "http://localhost:5454/entries?list=bob&date=20131219"
  get "/entries" do
    conn
    |> Plug.Conn.fetch_params
    |> fetch_entries
    |> respond
  end

  defp fetch_entries(conn) do
    entries = conn.params["list"]
    |> entries(parse_date(conn.params["date"]))
    |> format_entries

    Plug.Conn.assign(conn, :response, entries)
  end

  defp entries(list_name, date) do
    list_name
    |> Todo.Cache.server_process
    |> Todo.Server.entries(date)
  end

  defp format_entries(entries) do
    for %{date: {y,m,d}, title: title} <- entries, into: "" do
      "#{y}-#{m}-#{d}\t#{title}\n"
    end
  end

  # curl -d "" "http://localhost:5454/add_entry?list=bob&date=20131219&title=Chores"
  post "/add_entry" do
    conn
    |> Plug.Conn.fetch_params
    |> add_entry
    |> respond
  end

  defp add_entry(conn) do
    conn.params["list"]
    |> Todo.Cache.server_process
    |> Todo.Server.add_entry(%{
      date:  parse_date(conn.params["date"]),
      title: conn.params["title"]
    })

    Plug.Conn.assign(conn, :response, "OK")
  end

  defp parse_date(
    <<year::binary-size(4), month::binary-size(2), day::binary-size(2)>>
  ) do
    {String.to_integer(year), String.to_integer(month), String.to_integer(day)}
  end

  defp respond(conn) do
    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(200, conn.assigns[:response])
  end
end
