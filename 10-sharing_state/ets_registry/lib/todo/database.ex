defmodule Todo.Database do
  @moduledoc """
  Provides an interface to get and store key-value data on the disk.

  This module uses a pool of database workers to perform the actual disk
  operations.
  """

  @pool_size 3

  def start_link(db_folder) do
    IO.puts "Starting database server."
    Todo.PoolSupervisor.start_link(db_folder, @pool_size)
  end

  def store(key, data) do
    key
    |> choose_worker
    |> Todo.DatabaseWorker.store(key, data)
  end

  def get(key) do
    key
    |> choose_worker
    |> Todo.DatabaseWorker.get(key)
  end

  defp choose_worker(key), do: :erlang.phash2(key, @pool_size) + 1
end
