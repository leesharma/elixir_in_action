defmodule Todo.Database do
  use GenServer

  # interface functions

  def start_link(db_folder) do
    IO.puts "Starting database server."
    GenServer.start_link(__MODULE__, db_folder, name: :database_server)
  end

  def store(key, data) do
    GenServer.cast(:database_server, {:store, key, data})
  end

  def get(key) do
    GenServer.call(:database_server, {:get, key})
  end

  # callback functions

  def init(db_folder) do
    File.mkdir_p(db_folder)
    pool = for i <- 0..(num_workers-1), into: %{} do
      {:ok, worker} = Todo.DatabaseWorker.start_link(db_folder)
      {i, worker}
    end

    {:ok, pool}
  end

  def handle_cast({:store, key, data}, pool) do
    worker = pool[get_worker(key)]
    Todo.DatabaseWorker.store(worker, key, data)

    {:noreply, pool}
  end

  def handle_call({:get, key}, _caller, pool) do
    worker = pool[get_worker(key)]
    {:reply, Todo.DatabaseWorker.get(worker, key), pool}
  end

  defp get_worker(name), do: :erlang.phash2(name, num_workers)
  defp num_workers, do: 3
end
