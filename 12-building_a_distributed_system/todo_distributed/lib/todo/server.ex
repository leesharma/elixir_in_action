defmodule Todo.Server do
  use GenServer

  # interface functions

  def start_link(name) do
    IO.puts "Starting to-do server for #{name}"
    GenServer.start_link(__MODULE__, name,
                         name: {:global, {:todo_server, name}})
  end

  def entries(todo_server, date) do
    GenServer.call(todo_server, {:entries, date})
  end

  def add_entry(todo_server, new_entry) do
    GenServer.call(todo_server, {:add_entry, new_entry})
  end

  def whereis(name) do
    :global.whereis_name({:todo_server, name})
  end

  # callback functions

  def init(name) do
    # We're no longer loading the whole list right away: now we lazily load
    # entries by date as needed
    {:ok, {name, Todo.List.new}}
  end

  def handle_call({:entries, date}, _, {name, todo_list}) do
    new_list = initialize_entries(todo_list, name, date)
    {:reply, Todo.List.entries(new_list, date), {name, new_list}}
  end

  def handle_call({:add_entry, new_entry}, _, {name, todo_list}) do
    new_list =
      todo_list
      |> initialize_entries(name, new_entry.date)
      |> Todo.List.add_entry(new_entry)

    # we only store entries for a given date to balance clarity and performance
    Todo.Database.store(
      {name, new_entry.date},
      Todo.List.entries(new_list, new_entry.date)
    )

    {:reply, :ok, {name, new_list}}
  end

  def handle_info(:stop, state), do: {:stop, :normal, state}
  def handle_info(_, state), do: {:noreply, state}

  defp initialize_entries(todo_list, name, date) do
    case Todo.List.entries(todo_list, date) do
      nil ->
        entries = Todo.Database.get({name, date}) || []
        Todo.List.set_entries(todo_list, date, entries)

      _entries -> todo_list
    end
  end

  # Not needed for this exercise:
  # -----------------------------
  #
  # def update_entry(todo_server, entry_id, updater_fun) do
  #   GenServer.cast(todo_server, {:update_entry, entry_id, updater_fun})
  # end
  #
  # def update_entry(todo_server, new_entry) do
  #   GenServer.cast(todo_server, {:update_entry, new_entry})
  # end
  #
  # def delete_entry(todo_server, entry_id) do
  #   GenServer.cast(todo_server, {:delete_entry, entry_id})
  # end
  #
  #
  # def handle_cast({:update_entry, entry_id, updater_fun}, {name, todo_list}) do
  #   new_todo_list = Todo.List.update_entry(todo_list, entry_id, updater_fun)
  #   Todo.Database.store(name, new_todo_list)
  #   {:noreply, {name, new_todo_list}}
  # end
  # def handle_cast({:update_entry, new_entry}, {name, todo_list}) do
  #   new_todo_list = Todo.List.update_entry(todo_list, new_entry)
  #   Todo.Database.store(name, new_todo_list)
  #   {:noreply, {name, new_todo_list}}
  # end
  #
  # def handle_cast({:delete_entry, entry_id}, {name, todo_list}) do
  #   new_todo_list = Todo.List.delete_entry(todo_list, entry_id)
  #   Todo.Database.store(name, new_todo_list)
  #   {:noreply, {name, new_todo_list}}
  # end
end
