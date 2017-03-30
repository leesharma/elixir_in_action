defmodule DatabaseServer do
  def start do
    spawn(fn ->
      conn = :random.uniform(1000)
      loop(conn)
    end)
  end

  def loop(conn) do
    receive do
      {:run_query, caller, query_def} ->
        query_result = run_query(conn, query_def)
        send(caller, {:query_result, query_result})
    end

    loop(conn)
  end

  defp run_query(conn, query_def) do
    :timer.sleep(2000)
    "Connection #{conn}: #{query_def} result"
  end

  def run_async(server_pid, query_def) do
    send(server_pid, {:run_query, self, query_def})
  end

  def get_result do
    receive do
      {:query_result, result} -> result
    after 5000 -> {:error, :timeout}
    end
  end
end
