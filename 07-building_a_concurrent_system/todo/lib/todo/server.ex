defmodule Todo.Server do
  @moduledoc """
  A server to manage todo lists.

  Lists can do the basic CRUD actions. This iteration of the list uses the
  GenServer behaviour.
  """

  # interface functions

  @spec start() :: {:ok, pid}
  def start do
    GenServer.start(__MODULE__, nil)
  end

  @spec entries(pid, tuple) :: [map] | {:error, :timeout}
  def entries(todo_server, date) do
    GenServer.call(todo_server, {:entries, date})
  end

  @spec add_entry(pid, map) :: :ok
  def add_entry(todo_server, new_entry) do
    GenServer.cast(todo_server, {:add_entry, new_entry})
  end

  @spec update_entry(pid, integer, (map -> map)) :: :ok
  def update_entry(todo_server, entry_id, updater_fun) do
    GenServer.cast(todo_server, {:update_entry, entry_id, updater_fun})
  end

  @spec update_entry(pid, map) :: :ok
  def update_entry(todo_server, new_entry) do
    GenServer.cast(todo_server, {:update_entry, new_entry})
  end

  @spec delete_entry(pid, integer) :: :ok
  def delete_entry(todo_server, entry_id) do
    GenServer.cast(todo_server, {:delete_entry, entry_id})
  end

  # callback functions

  def init(_), do: {:ok, Todo.List.new}

  def handle_call({:entries, date}, _, todo_list) do
    {:reply, Todo.List.entries(todo_list, date), todo_list}
  end

  def handle_cast({:add_entry, new_entry}, todo_list) do
    {:noreply, Todo.List.add_entry(todo_list, new_entry)}
  end

  def handle_cast({:update_entry, entry_id, updater_fun}, todo_list) do
    {:noreply, Todo.List.update_entry(todo_list, entry_id, updater_fun)}
  end
  def handle_cast({:update_entry, new_entry}, todo_list) do
    {:noreply, Todo.List.update_entry(todo_list, new_entry)}
  end

  def handle_cast({:delete_entry, entry_id}, todo_list) do
    {:noreply, Todo.List.delete_entry(todo_list, entry_id)}
  end
end
