defmodule Todo.Database do
  @moduledoc """
  Server process responsible for managing persisted data through `store/2` and
  `get/1`.

  Only one Todo.Database process can be started with the command `start/1`.
  """

  @vsn 0.1

  use GenServer

  @typedef "A todo list name, which must behave like a string"
  @type key :: String.t | atom | number

  @worker_count 3

  @spec start(String.t) :: {:ok, pid}
  def start(db_folder) do
    GenServer.start(__MODULE__, db_folder, name: :database_server)
  end

  @spec store(key, any) :: :ok
  def store(key, data) do
    key
    |> get_worker
    |> Todo.DatabaseWorker.store(key, data)
  end

  @spec get(key) :: any
  def get(key) do
    key
    |> get_worker
    |> Todo.DatabaseWorker.get(key)
  end

  def init(db_folder) do
    File.mkdir_p(db_folder)
    workers = start_n_workers(db_folder, @worker_count)

    {:ok, workers}
  end

  defp start_n_workers(db_folder, count) do
    for i <- 0..(count - 1), into: %{} do
      {:ok, worker} = Todo.DatabaseWorker.start(db_folder)
      {i, worker}
    end
  end

  defp get_worker(key) do
    GenServer.call(:database_server, {:get_worker, key})
  end

  def handle_call({:get_worker, key}, _, workers) do
    index = :erlang.phash2(key, @worker_count)
    {:reply, workers[index], workers}
  end

 # Needed for testing purposes
  def handle_info(:stop, workers) do
    workers
    |> Enum.each(fn({_, worker}) ->
      send(worker, :stop)
    end)

    {:stop, :normal, HashDict.new}
  end
	def handle_info(_, state), do: {:noreply, state}
end

