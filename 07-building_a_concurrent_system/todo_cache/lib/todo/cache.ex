defmodule Todo.Cache do
  @moduledoc false

  use GenServer

  # interface functions

  def start, do: GenServer.start(__MODULE__, nil)

  def server_process(cache_pid, todo_list_name) do
    GenServer.call(cache_pid, {:server_process, todo_list_name})
  end

  # callback functions

  def init(_), do: {:ok, %{}} # not great with elixir 1.0.5 + many entries

  def handle_call({:server_process, todo_list_name}, _, todo_servers) do
    case Map.fetch(todo_servers, todo_list_name) do
      {:ok, todo_server} ->
        {:reply, todo_server, todo_servers}

      :error ->
        {:ok, new_server} = Todo.Server.start

        {
          :reply,
          new_server,
          Map.put(todo_servers, todo_list_name, new_server)
        }
    end
  end
end
