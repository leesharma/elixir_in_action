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


defmodule TodoList do
  @moduledoc """
  A to-do list that can read input from a file
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
