defmodule Todo.DatabaseWorker do
  @moduledoc false
  @vsn 0.1

  use GenServer

  def start(db_folder) do
    GenServer.start(__MODULE__, db_folder)
  end

  def store(pid, key, data) do
    GenServer.cast(pid, {:store, key, data})
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  def init(db_folder) do
    File.mkdir_p(db_folder)
    {:ok, db_folder}
  end

  def handle_cast({:store, key, data}, db_folder) do
    # IO.puts "#{inspect self}: storing #{key}"
    file_name(db_folder, key)
    |> File.write!(:erlang.term_to_binary(data))

    {:noreply, db_folder}
  end

  def handle_call({:get, key}, caller, db_folder) do
    # IO.puts "#{inspect self}: retrieving #{key}"
    data = case File.read(file_name(db_folder, key)) do
      {:ok, contents} -> :erlang.binary_to_term(contents)
      _ -> nil
    end

    {:reply, data, db_folder}
  end

	# Needed for testing purposes
  def handle_info(:stop, state), do: {:stop, :normal, state}
	def handle_info(_, state), do: {:noreply, state}

  defp file_name(db_folder, key), do: "#{db_folder}/#{key}"
end
