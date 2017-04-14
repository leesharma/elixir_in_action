defmodule Todo.List do
  @moduledoc """
  A simple to-do list
  """

  # We're now indexing todo lists by days so that entries can be retrieved
  # more quickly and read/manipulated in smaller chunks.

  defstruct days: %{}, size: 0

  def new(entries \\ []) do
    Enum.reduce(entries, %Todo.List{}, &add_entry(&2, &1))
  end

  def add_entry(todo_list, entry) do
    %Todo.List{todo_list |
      days: Map.update(todo_list.days, entry.date, [entry], &[entry | &1]),
      size: todo_list.size + 1
    }
  end

  def entries(%Todo.List{days: days}, date) do
    days[date]
  end

  def set_entries(todo_list, date, entries) do
    %Todo.List{todo_list | days: Map.put(todo_list.days, date, entries)}
  end

  # Not needed for this exercise:
  # -----------------------------
  # def update_entry(
  #   %Todo.List{entries: entries} = todo_list,
  #   entry_id,
  #   updater_fun
  # ) do
  #   case entries[entry_id] do
  #     nil -> todo_list
  #
  #     old_entry ->
  #       old_entry_id = old_entry.id
  #       new_entry = %{id: ^old_entry_id} = updater_fun.(old_entry)
  #       new_entries = Map.put(entries, new_entry.id, new_entry)
  #       %Todo.List{todo_list | entries: new_entries}
  #   end
  # end
  #
  # def update_entry(todo_list, %{} = new_entry) do
  #   update_entry(todo_list, new_entry.id, fn(_) -> new_entry end)
  # end
  #
  # def delete_entry(%Todo.List{entries: entries} = todo_list, entry_id) do
  #   new_entries = Map.delete(entries, entry_id)
  #   %Todo.List{todo_list | entries: new_entries}
  # end
end
