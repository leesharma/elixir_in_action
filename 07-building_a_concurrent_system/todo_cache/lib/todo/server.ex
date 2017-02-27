defmodule Todo.Server do
  @moduledoc """
  A server for interacting with a named todo list.
  """

  @vsn 0.4

  use GenServer

  @typedoc "Date tuple, consisting of three items: year, month, and day"
  @type date :: {integer, integer, integer}

  @typedoc "Todo list entry, consisting of a date tuple and a title"
  @type entry :: %{date: date, title: String.t}

  # Client Functions

  @spec start(any) :: true
  def start(name) do
    GenServer.start(Todo.Server, name)
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

  @spec init(any) :: {:ok, nil}
  def init(name) do
    send(self, {:real_init, name})
    {:ok, nil}
  end

  @spec handle_info({:real_init, any}, any) :: {:noreply, {any, [entry]}}
  def handle_info({:real_init, name}, _state) do
    {:noreply, {name, Todo.Database.get(name) || Todo.List.new}}
  end

  @spec handle_call(tuple, tuple, {any, [entry]}) :: {:reply, [entry], [entry]}
  def handle_call({:entries, date}, _from, {name, todo_list}) do
    matching_entries = Todo.List.entries(todo_list, date)
    {:reply, matching_entries, {name, todo_list}}
  end

  @spec handle_cast(tuple, {any, [entry]}) :: {:noreply, [entry]}
  def handle_cast({:add_entry, entry}, {name, todo_list}) do
    Todo.List.add_entry(todo_list, entry)
    |> persist_cast(name)
  end
  def handle_cast({:delete_entries, matcher}, {name, todo_list}) do
    Todo.List.delete_entries(todo_list, matcher)
    |> persist_cast(name)
  end
  def handle_cast({:delete_entry, id}, {name, todo_list}) do
    Todo.List.delete_entry(todo_list, id)
    |> persist_cast(name)
  end

  defp persist_cast(new_todo_list, name) do
    Todo.Database.store(name, new_todo_list)
    {:noreply, {name, new_todo_list}}
  end

  # Needed for testing purposes
  def handle_info(:stop, state), do: {:stop, :normal, state}
  def handle_info(_, state), do: {:noreply, state}
end
