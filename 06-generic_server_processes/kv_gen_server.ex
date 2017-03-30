defmodule KeyValueStore do
  @moduledoc """
  A basic key value store using GenServer.

  The server can be started with `start/0`, and then elements can be inserted
  and looked up with `put/3` and `get/3`, respectively.
  """

  use GenServer

  # callback functions

  def init(_) do
    :timer.send_interval(5_000, :cleanup)
    {:ok, %{}}
  end

  def handle_cast({:put, key, value}, state) do
    {:noreply, Map.put(state, key, value)}
  end

  def handle_call({:get, key}, _, state) do
    {:reply, Map.get(state, key), state}
  end

  def handle_info(:cleanup, state) do
    IO.puts "performing cleanup..."
    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}

  # interface functions

  def start, do: GenServer.start(__MODULE__, nil)

  def put(pid, key, value) do
    GenServer.cast(pid, {:put, key, value})
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end
end
