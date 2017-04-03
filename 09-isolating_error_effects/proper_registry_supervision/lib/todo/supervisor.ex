defmodule Todo.Supervisor do
  @moduledoc """
  Starts and supervises the todo application.

  This is the root node of the todo supervision tree.
  """

  use Supervisor

  # interface functions

  def start_link do
    Supervisor.start_link(__MODULE__, nil)
  end

  # callback functions

  def init(_) do
    processes = [
      worker(Todo.ProcessRegistry, []),
      supervisor(Todo.SystemSupervisor, []),
    ]
    supervise(processes, strategy: :rest_for_one)
  end
end
