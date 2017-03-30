defmodule TodoServer do
  @moduledoc """
  A server to manage todo lists. Lists can do the basic CRUD actions.
  """

  # the basic server

  @spec start() :: true
  def start do
    fn -> loop(TodoList.new) end
    |> spawn
    |> Process.register(:todo_server)
  end

  defp loop(todo_list) do
    new_todo_list = receive do
      message -> process_message(todo_list, message)
    end
    loop(new_todo_list)
  end

  # public crud actions

  @spec add_entry(map) :: tuple
  def add_entry(new_entry) do
    send(:todo_server, {:add_entry, new_entry})
  end

  @spec entries(tuple) :: [map] | {:error, :timeout}
  def entries(date) do
    send(:todo_server, {:entries, self(), date})

    receive do
      {:todo_entries, entries} -> entries
    after 5000 ->
      {:error, :timeout}
    end
  end

  @spec update_entry(integer, (map -> map)) :: tuple
  def update_entry(entry_id, updater_fun) do
    send(:todo_server, {:update_entry, entry_id, updater_fun})
  end

  @spec update_entry(map) :: tuple
  def update_entry(new_entry) do
    send(:todo_server, {:update_entry, new_entry})
  end

  @spec delete_entry(integer) :: tuple
  def delete_entry(entry_id) do
    send(:todo_server, {:delete_entry, entry_id})
  end

  # process message

  defp process_message(todo_list, {:add_entry, new_entry}) do
    TodoList.add_entry(todo_list, new_entry)
  end

  defp process_message(todo_list, {:entries, caller, date}) do
    send(caller, {:todo_entries, TodoList.entries(todo_list, date)})
    todo_list
  end

  defp process_message(todo_list, {:update_entry, entry_id, updater_fun}) do
    TodoList.update_entry(todo_list, entry_id, updater_fun)
  end
  defp process_message(todo_list, {:update_entry, new_entry}) do
    TodoList.update_entry(todo_list, new_entry)
  end

  defp process_message(todo_list, {:delete_entry, entry_id}) do
    TodoList.delete_entry(todo_list, entry_id)
  end
end



defmodule TodoList do
  @moduledoc """
  A simple to-do list
  """

  defstruct auto_id: 1, entries: %{}

  def new(entries \\ []) do
    Enum.reduce(entries, %TodoList{}, &add_entry(&2, &1))
  end

  # CREATE

  def add_entry(
    %TodoList{entries: entries, auto_id: auto_id} = todo_list,
    entry
  ) do
    entry = Map.put(entry, :id, auto_id)
    new_entries = Map.put(entries, auto_id, entry)

    %TodoList{todo_list | entries: new_entries, auto_id: auto_id + 1}
  end

  # READ

  def entries(%TodoList{entries: entries}, date) do
    entries
    |> Stream.filter(fn({_, entry}) -> entry.date == date end)
    |> Enum.map(fn({_, entry}) -> entry end)
  end

  # UPDATE

  def update_entry(
    %TodoList{entries: entries} = todo_list,
    entry_id,
    updater_fun
  ) do
    case entries[entry_id] do
      nil -> todo_list

      old_entry ->
        old_entry_id = old_entry.id
        new_entry = %{id: ^old_entry_id} = updater_fun.(old_entry)
        new_entries = Map.put(entries, new_entry.id, new_entry)
        %TodoList{todo_list | entries: new_entries}
    end
  end

  def update_entry(todo_list, %{} = new_entry) do
    update_entry(todo_list, new_entry.id, fn(_) -> new_entry end)
  end

  # DELETE

  def delete_entry(%TodoList{entries: entries} = todo_list, entry_id) do
    new_entries = Map.delete(entries, entry_id)
    %TodoList{todo_list | entries: new_entries}
  end
end


defmodule TodoList.CsvImporter do
  @defmodule """
  Imports a CSV of entries from an external file and returns a Todo list
  """

  def import(filename) do
    filename
    |> read_lines
    |> create_entries
    |> TodoList.new
  end

  defp read_lines(filename) do
    filename
    |> File.stream!
    |> Stream.map(&String.replace(&1, "\n", ""))
  end

  defp create_entries(lines) do
    lines
    |> Stream.map(&extract_data/1)
    |> Stream.map(&format_entry/1)
  end

  defp extract_data(line) do
    [date, title] = String.split(line, ",")
    {parse_date(date), title}
  end

  defp format_entry({date, title}) do
    %{date: date, title: title}
  end

  defp parse_date(date) do
    date
    |> String.split("/")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple
  end
end


defimpl Collectable, for: TodoList do
  def into(original) do
    {original, &into_callback/2}
  end

  defp into_callback(todo_list, {:cont, entry}) do
    TodoList.add_entry(todo_list, entry)
  end

  defp into_callback(todo_list, :done),  do: todo_list
  defp into_callback(_todo_list, :halt), do: :ok
end
