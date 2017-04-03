defmodule Todo.ProcessRegistry do
  @moduledoc """
  Manages processes named with arbitrary terms.

  This module is designed to work with a GenServer using the :via tuple.
  """

  use GenServer

  import Kernel, except: [send: 2]

  # interface functions

  def start_link do
    IO.puts "Starting process registry."
    GenServer.start_link(__MODULE__, nil, name: :process_registry)
  end

  def register_name(name, pid) do
    GenServer.call(:process_registry, {:register_name, name, pid})
  end

  def whereis_name(name) do
    GenServer.call(:process_registry, {:whereis_name, name})
  end

  def unregister_name(name) do
    GenServer.cast(:process_registry, {:unregister_name, name})
  end

  def send(name, message) do
    case whereis_name(name) do
      :undefined -> {:badarg, {name, message}}
      pid ->
        Kernel.send(pid, message)
        pid
    end
  end

  # callback functions

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:register_name, name, pid}, _, process_registry) do
    case process_registry[name] do
      nil ->
        Process.monitor(pid)
        {:reply, :yes, Map.put(process_registry, name, pid)}
      _ ->
        {:reply, :no, process_registry}
    end
  end

  def handle_call({:whereis_name, name}, _, process_registry) do
    {
      :reply,
      Map.get(process_registry, name, :undefined),
      process_registry
    }
  end

  def handle_cast({:unregister_name, name}, process_registry) do
    new_registry = Map.delete(process_registry, name)
    {:noreply, new_registry}
  end

  def handle_info({:DOWN, _, :process, pid, _}, process_registry) do
    {:noreply, deregister_pid(process_registry, pid)}
  end

  defp deregister_pid(process_registry, bad_pid) do
    process_registry
    |> Enum.reject(fn {_, pid} -> pid == bad_pid end)
    |> Enum.into(%{})
  end
end
