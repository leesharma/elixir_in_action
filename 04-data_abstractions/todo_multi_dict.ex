defmodule MultiDict do
  @moduledoc """
  A key value store in which each key matches to a list of values.
  """

  def new, do: %{}

  def add(dict, key, value) do
    Map.update(dict, key, [value], &[value | &1])
  end

  def get(dict, key) do
    dict[key] || []
  end
end

defmodule TodoList do
  @moduledoc """
  A basic to-do list
  """

  def new, do: MultiDict.new

  def add_entry(todo_list, date, title) do
    MultiDict.add(todo_list, date, title)
  end

  def entries(todo_list, date) do
    MultiDict.get(todo_list, date)
  end

  def due_today(todo_list) do
    entries(todo_list, :erlang.date)
  end
end
