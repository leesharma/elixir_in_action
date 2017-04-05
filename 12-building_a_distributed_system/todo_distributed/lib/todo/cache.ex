defmodule Todo.Cache do
  @moduledoc """
  A cache of todo server processes.
  """

  def server_process(todo_list_name) do
    # first check to reduce node chatter
    case Todo.Server.whereis(todo_list_name) do
      :undefined -> create_server(todo_list_name)
      pid -> pid
    end
  end

  def create_server(todo_list_name) do
    case Todo.ServerSupervisor.start_child(todo_list_name) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end
end
