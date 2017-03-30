defmodule KeyValueStore do
  @moduledoc """
  A basic key value server.

  The server can be started with `start/0`, and then elements can be inserted
  and looked up with `put/3` and `get/3`, respectively.
  """

  # callback functions

  def init, do: %{}

  def handle_call({:get, key}, state) do
    {Map.get(state, key), state}
  end

  def handle_cast({:put, key, value}, state) do
    Map.put(state, key, value)
  end

  # interface functions

  def start, do: ServerProcess.start(__MODULE__)

  def put(pid, key, value) do
    ServerProcess.cast(pid, {:put, key, value})
  end

  def get(pid, key) do
    ServerProcess.call(pid, {:get, key})
  end
end


defmodule ServerProcess do
  @moduledoc """
  A generic server abstraction.
  """

  def start(callback_module) do
    spawn(fn ->
      initial_state = callback_module.init
      loop(callback_module, initial_state)
    end)
  end

  defp loop(callback_module, current_state) do
    receive do
      {:call, request, caller} ->
        {response, new_state} = callback_module.handle_call(
          request,
          current_state
        )
        send(caller, {:response, response})

        loop(callback_module, new_state)

      {:cast, request} ->
        new_state = callback_module.handle_cast(
          request,
          current_state
        )
        loop(callback_module, new_state)
    end
  end

  def call(server_pid, request) do
    send(server_pid, {:call, request, self})

    receive do
      {:response, response} -> response
    end
  end

  def cast(server_pid, request) do
    send(server_pid, {:cast, request})
  end
end
