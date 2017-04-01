defmodule Todo.Server do
  @moduledoc """
  A server to manage todo lists.

  Lists can do the basic CRUD actions. This iteration of the list uses the
  GenServer behaviour.
  """

  # interface functions

  def start(name) do
    GenServer.start(__MODULE__, name)
  end

  def entries(todo_server, date) do
    GenServer.call(todo_server, {:entries, date})
  end

  def add_entry(todo_server, new_entry) do
    GenServer.cast(todo_server, {:add_entry, new_entry})
  end

  def update_entry(todo_server, entry_id, updater_fun) do
    GenServer.cast(todo_server, {:update_entry, entry_id, updater_fun})
  end

  def update_entry(todo_server, new_entry) do
    GenServer.cast(todo_server, {:update_entry, new_entry})
  end

  def delete_entry(todo_server, entry_id) do
    GenServer.cast(todo_server, {:delete_entry, entry_id})
  end

  # callback functions

  def init(name) do
    send(self(), {:init, name})
    {:ok, nil}
  end

  # bit of a hack, probably not needed here in real life
  def handle_info({:init, name}, _state) do
    {:noreply, {name, Todo.Database.get(name) || Todo.List.new}}
  end

  def handle_call({:entries, date}, _, {name, todo_list}) do
    {:reply, Todo.List.entries(todo_list, date), {name, todo_list}}
  end

  def handle_cast({:add_entry, new_entry}, {name, todo_list}) do
    new_todo_list = Todo.List.add_entry(todo_list, new_entry)
    Todo.Database.store(name, new_todo_list)
    {:noreply, {name, new_todo_list}}
  end

  def handle_cast({:update_entry, entry_id, updater_fun}, {name, todo_list}) do
    new_todo_list = Todo.List.update_entry(todo_list, entry_id, updater_fun)
    Todo.Database.store(name, new_todo_list)
    {:noreply, {name, new_todo_list}}
  end
  def handle_cast({:update_entry, new_entry}, {name, todo_list}) do
    new_todo_list = Todo.List.update_entry(todo_list, new_entry)
    Todo.Database.store(name, new_todo_list)
    {:noreply, {name, new_todo_list}}
  end

  def handle_cast({:delete_entry, entry_id}, {name, todo_list}) do
    new_todo_list = Todo.List.delete_entry(todo_list, entry_id)
    Todo.Database.store(name, new_todo_list)
    {:noreply, {name, new_todo_list}}
  end
end
