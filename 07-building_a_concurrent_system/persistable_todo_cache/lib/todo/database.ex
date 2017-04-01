defmodule Todo.Database do
  use GenServer

  # interface functions

  def start(db_folder) do
    GenServer.start(__MODULE__, db_folder, name: :todo_database)
  end

  def store(key, data) do
    GenServer.cast(:todo_database, {:store, key, data})
  end

  def get(key) do
    GenServer.call(:todo_database, {:get, key})
  end

  # callback functions

  def init(db_folder), do: {:ok, db_folder}

  def handle_cast({:store, key, data}, db_folder) do
    file_name(db_folder, key)
    |> File.write!(:erlang.term_to_binary(data))

    {:noreply, db_folder}
  end

  def handle_call({:get, key}, _caller, db_folder) do
    data = case File.read(file_name(db_folder, key)) do
      {:ok, contents} -> :erlang.binary_to_term(contents)
      _ -> nil
    end

    {:reply, data, db_folder}
  end

  defp file_name(db_folder, key), do: "#{db_folder}/#{key}"
end
