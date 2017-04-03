defmodule Todo.Supervisor do
  use Supervisor

  # interface functions

  def start_link do
    Supervisor.start_link(__MODULE__, nil)
  end

  # callback functions

  def init(_) do
    processes = [
      worker(Todo.Database, ["./persist"]),
      worker(Todo.Cache, []),
    ]
    supervise(processes, strategy: :one_for_one)
  end
end
