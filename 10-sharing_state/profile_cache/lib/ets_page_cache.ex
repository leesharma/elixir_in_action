defmodule EtsPageCache do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: :ets_page_cache)
  end

  def cached(key, fun) do
    # using a GenServer serializes writes
    read_cached(key) ||
      GenServer.call(:ets_page_cache, {:cached, key, fun})
  end

  defp read_cached(key) do
    case :ets.lookup(:ets_page_cache, key) do
      [{^key, cached}] -> cached
      _ -> nil
    end
  end

  def init(_) do
    :ets.new(:ets_page_cache, [:set, :named_table, :protected])
    {:ok, nil}
  end

  def handle_call({:cached, key, fun}, _, state) do
    {
      :reply,
      # second cache lookup to prevent race conditions
      read_cached(key) || cache_response(key, fun),
      state
    }
  end

  defp cache_response(key, fun) do
    response = fun.()
    # spin off as separate processes for faster writes
    :ets.insert(:ets_page_cache, {key, response})
    response
  end
end
