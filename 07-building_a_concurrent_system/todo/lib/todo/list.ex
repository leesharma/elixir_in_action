defmodule Todo.List do
  @moduledoc false
  @vsn 0.1

  @typedoc "Date tuple, consisting of three items: year, month, and day"
  @type date :: {integer, integer, integer}

  @typedoc "Todo list entry, consisting of a date tuple and a title"
  @type entry :: %{date: date, title: String.t}

  @spec new :: []
  def new do
    []
  end

  @spec add_entry([entry], entry) :: [entry]
  def add_entry(todo_list, entry) do
    entry = Map.put(entry, :id, Enum.count(todo_list))
    [entry | todo_list]
  end

  @spec delete_entries([entry], %{}) :: [entry]
  def delete_entries(todo_list, delete_terms) do
    todo_list
    |> Enum.reject(&superset?(&1, delete_terms))
  end

  @spec delete_entry([entry], integer) :: [entry]
  def delete_entry(todo_list, id) do
    todo_list
    |> Enum.reject(fn
      (%{id: ^id}) -> true
      (_)          -> false
    end)
  end

  defp superset?(map, match_terms) do
    matches = for x <- match_terms, y <- map, x == y, into: %{}, do: x
    matches == match_terms
  end

  @spec entries([entry], date) :: [entry]
  def entries(todo_list, date) do
    for entry <- todo_list, entry[:date] == date, do: entry
  end
end
