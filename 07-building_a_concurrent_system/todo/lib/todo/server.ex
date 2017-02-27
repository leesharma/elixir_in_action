defmodule Todo.Server do
  @moduledoc """
  A server for interacting with a todo list.
  """

  @vsn 0.4

  use GenServer

  @typedoc "Date tuple, consisting of three items: year, month, and day"
  @type date :: {integer, integer, integer}

  @typedoc "Todo list entry, consisting of a date tuple and a title"
  @type entry :: %{date: date, title: String.t}

  # Client Functions

  @spec start :: true
  def start do
    GenServer.start(Todo.Server, Todo.List.new)
  end

  @spec stop(pid) :: :ok
  def stop(pid) do
    GenServer.stop(pid)
  end

  @spec delete_entries(pid, map) :: :ok
  def delete_entries(pid, matcher) do
    GenServer.cast(pid, {:delete_entries, matcher})
  end

  @spec delete_entry(pid, integer) :: :ok
  def delete_entry(pid, id) do
    GenServer.cast(pid, {:delete_entry, id})
  end

  @spec add_entry(pid, entry) :: :ok
  def add_entry(pid, entry) do
    GenServer.cast(pid, {:add_entry, entry})
  end

  @spec entries(pid, date) :: [entry]
  def entries(pid, date) do
    GenServer.call(pid, {:entries, date})
  end

  # Server Functions

  @spec handle_call(tuple, tuple, [entry]) :: {:reply, [entry], [entry]}
  def handle_call({:entries, date}, _from, todo_list) do
    matching_entries = Todo.List.entries(todo_list, date)
    {:reply, matching_entries, todo_list}
  end

  @spec handle_cast(tuple, [entry]) :: {:noreply, [entry]}
  def handle_cast({:add_entry, entry}, todo_list) do
    new_todo_list = Todo.List.add_entry(todo_list, entry)
    {:noreply, new_todo_list}
  end
  def handle_cast({:delete_entries, matcher}, todo_list) do
    new_todo_list = Todo.List.delete_entries(todo_list, matcher)
    {:noreply, new_todo_list}
  end
  def handle_cast({:delete_entry, id}, todo_list) do
    new_todo_list = Todo.List.delete_entry(todo_list, id)
    {:noreply, new_todo_list}
  end
end
