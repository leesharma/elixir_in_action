defmodule Todo.DatabaseWorker do
  use GenServer

  # interface functions

  def start_link(worker_id) do
    IO.puts "Starting database worker ##{worker_id}."

    GenServer.start_link(
      __MODULE__, nil,
      name: via_tuple(worker_id)
    )
  end

  def store(worker_id, key, data) do
    GenServer.call(via_tuple(worker_id), {:store, key, data})
  end

  def get(worker_id, key) do
    GenServer.call(via_tuple(worker_id), {:get, key})
  end

  defp via_tuple(worker_id) do
    {:via, Registry, {Todo.Registry, {:database_worker, worker_id}}}
  end

  # callback functions

  def init(_) do
    # Comment from official repo:
    # ---------------------------
    # Instead of performing one request at a time, the worker tries to adapt to
    # the increased load by batching requests.
    #
    # This is done by internally spawning another process to perform the storing.
    # While the worker is doing its job, we will put all incoming requests into
    # the queue. When the worker finishes, we'll start the next worker and
    # store the entire queue in a single pass.
    #
    # This is beneficial, since storing of N items in a single go is much faster
    # than storing those items one by one.
    #
    # Another nice thing is that we can avoid excessive storing in some cases.
    # If a request arrives for the item which is already in the queue, the old
    # request will be overwritten, and we'll store just one item.
    {
      :ok,
      %{
        store_job: nil,
        store_queue: %{},
      }
    }
  end

  def handle_call({:store, key, data}, caller, state) do
    new_state =
      state
      |> queue_request(caller, key, data)
      |> maybe_store # reply sent here

    {:noreply, new_state}
  end

  def handle_call({:get, key}, _caller, state) do
    read_result = :mnesia.transaction(fn -> :mnesia.read({:todo_lists, key}) end)

    data = case read_result do
      {:atomic, [{:todo_lists, ^key, list}]} -> list
      _ -> nil
    end

    {:reply, data, state}
  end

  # Received when store_job is done storing
  def handle_info(
    {:DOWN, _, :process, pid, _},%{store_job: store_job} = state
  ) when pid == store_job do
    # We clear the store_job and immediately invoke maybe_store, which will in
    # turn start another store job if something is in the queue.
    {:noreply, maybe_store(%{state | store_job: nil})}
  end

  def handle_info(:stop, state), do: {:stop, :normal, state}
  def handle_info(_, state), do: {:noreply, state}


  defp queue_request(state, caller, key, data) do
    %{state | store_queue: Map.put(state.store_queue, key, {caller, data})}
  end

  defp maybe_store(%{store_job: nil} = state) do
    # store_job is nil, so there's nothing currently storing, so we can safely
    # start storing the queue
    if Map.size(state.store_queue) > 0 do
      start_store_job(state)
    else
      state # queue is empty, so nothing to do
    end
  end
  # store_job is currently running, so we don't do anything
  defp maybe_store(state), do: state

  defp start_store_job(state) do
    # spawn_link so if store_job crashes, the worker will crash and vice-versa
    store_job = spawn_link(fn -> do_write(state.store_queue) end)
    # monitor the process so we can remove the finished store_job
    # (see the relevant `handle_info` clause above)
    Process.monitor(store_job)

    %{
      state |
      store_queue: %{},
      store_job: store_job,
    }
  end

  defp do_write(store_queue) do
    # write all transactions in queue
    {:atomic, :ok} = :mnesia.transaction(fn ->
      for {key, {_, data}} <- store_queue do
        :ok = :mnesia.write({:todo_lists, key, data})
      end
      :ok
    end)

    # reply to all callers
    for {_, {caller, _}} <- store_queue, do: GenServer.reply(caller, :ok)
  end
end
