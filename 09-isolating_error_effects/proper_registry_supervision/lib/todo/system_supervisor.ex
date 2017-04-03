defmodule Todo.SystemSupervisor do
  @moduledoc """
  Starts and supervises the todo system.

  This supervisor assumes that the process registry is already up and running;
  it will not work without it.
  """

  use Supervisor

  # interface functions

  def start_link do
    IO.puts "Starting system supervisor."
    Supervisor.start_link(__MODULE__, nil,
                          name: :todo_system_supervisor)
  end

  # callback functions

  def init(_) do
    processes = [
      supervisor(Todo.Database, ["./persist"]),
      supervisor(Todo.ServerSupervisor, []),
      worker(Todo.Cache, []),
    ]
    supervise(processes, strategy: :one_for_one)
  end
end
