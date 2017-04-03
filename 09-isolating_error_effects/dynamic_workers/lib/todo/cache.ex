defmodule Todo.Cache do
  @moduledoc false

  use GenServer

  # interface functions

  def start_link do
    IO.puts "Starting to-do cache."
    GenServer.start_link(__MODULE__, nil, name: :todo_cache)
  end

  def server_process(todo_list_name) do
    case Todo.Server.whereis(todo_list_name) do
      :undefined ->
        GenServer.call(:todo_cache, {:server_process, todo_list_name})

      pid -> pid
    end
  end

  # callback functions

  def init(_), do: {:ok, nil}

  def handle_call({:server_process, todo_list_name}, _, state) do
    todo_server = case Todo.Server.whereis(todo_list_name) do
      :undefined ->
        {:ok, new_server} = Todo.ServerSupervisor.start_child(todo_list_name)
        new_server

      pid -> pid
    end

    {:reply, todo_server, state}
  end
end
