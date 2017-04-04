defmodule Todo.PoolSupervisor do
  @moduledoc """
  Supervises a pool of database workers.
  """

  use Supervisor

  # interface functions

  def start_link(db_folder, pool_size) do
    IO.puts "Starting pool supervisor."
    Supervisor.start_link(__MODULE__, {db_folder, pool_size})
  end

  # callback functions

  def init({db_folder, pool_size}) do
    processes = for worker_id <- 1..pool_size do
      worker(
        Todo.DatabaseWorker, [db_folder, worker_id],
        id: {:database_worker, worker_id}
      )
    end

    supervise(processes, strategy: :one_for_one)
  end
end
