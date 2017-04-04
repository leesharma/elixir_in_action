defmodule Todo.ProcessRegistry do
  @moduledoc """
  An ETS-based process registry
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

  def unregister_name(name) do
    GenServer.cast(:process_registry, {:unregister_name, name})
  end

  # public async reads for faster response
  def whereis_name(name) do
    case :ets.lookup(:process_registry, name) do
      [{^name, pid}] -> pid
      _              -> :undefined
    end
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
    :ets.new(:process_registry, [:set, :named_table, :protected])
    {:ok, nil}
  end

  def handle_call({:register_name, key, pid}, _, state) do
    case whereis_name(key) do
      :undefined ->
        Process.monitor(pid)
        :ets.insert(:process_registry, {key, pid})
        {:reply, :yes, state}
      _ ->
        {:reply, :no, state}
    end
  end

  def handle_cast({:unregister_name, name}, state) do
    :ets.delete(:process_registry, name)
    {:noreply, state}
  end

  def handle_info({:DOWN, _, :process, bad_pid, _}, state) do
    :ets.match_delete(:process_registry, {:_, bad_pid})
    {:noreply, state}
  end
  def handle_info(_, state), do: {:noreply, state}
end
