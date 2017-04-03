defmodule Profiler.CLI do
  @moduledoc """
  World's hackiest CLI script! This is for profiling.
  """

  @defaults [
    reps: 10,
    calls: 100_000,
    concurrency: 100,
    module: PageCache,
  ]

  def main(args) do
    args
    |> parse_args
    |> print_help
    |> set_defaults
    |> IO.inspect
    |> print_query
    |> query
    |> print_results
  end

  defp parse_args(args) do
    {parsed, _, _} = OptionParser.parse(args, strict: [
      reps: :integer,
      calls: :integer,
      ccalls: :integer,
      concurrency: :integer,
      ets: :boolean,
      help: :boolean,
    ])
    parsed
  end

  defp print_help(parsed) do
    case parsed[:help] do
      nil -> parsed
      true ->
        IO.puts """
        Usage:
        ./profile_cache [--reps num] [--calls num] [--ccalls num]
                        [--concurrency num] [--ets] [--help]

        Options:
        --reps num
            # of times to repeat test (default: 10)
        --calls num
            # requests to send in the synchronous test (default: 100_000)
        --ccalls num
            # requests per sender to send in the async test (default: ==calls)
        --concurrency num
            # of concurrent sender processes in async test (default: 100)
        --ets
            profile EtsPageCache module (default: PageCache)
        --help
            show this help message.

        Description:
        Allows for easy adjustment and bulk-running for `Profiler`, as used
        in Elixir in Action, Chapter 10.
        """
        System.halt(0)
    end
  end

  defp set_defaults(parsed) do
    # calls and concurrent calls are same by default
    [ccalls: parsed[:calls] || @defaults[:calls]]
    |> Keyword.merge(@defaults)
    |> set_module(parsed[:ets])
    |> Keyword.merge(parsed)
  end

  defp set_module(options, true), do: Keyword.put(options, :module, EtsPageCache)
  defp set_module(options, _), do: options

  defp print_query(parsed) do
    parsed |> query_template |> IO.puts
    parsed
  end

  defp query_template(parsed) do
    """

    sync  = fn _ -> Profiler.run(#{parsed[:module]}, #{parsed[:calls]}) end
    async = fn _ -> Profiler.run(#{parsed[:module]}, #{parsed[:ccalls]}, \
    #{parsed[:concurrency]}) end

    results = for {name, strategy} <- [sync: sync, async: async] do
      IO.puts "Running \#\{inspect name\}..."
      {
        name,
        1..#{parsed[:reps]} |> Enum.map(strategy)
      }
    end
    """
  end

  defp query(parsed) do
    sync  = fn _ -> Profiler.run(parsed[:module], parsed[:calls]) end
    async = fn _ ->
      Profiler.run(parsed[:module], parsed[:ccalls], parsed[:concurrency])
    end

    for {name, strategy} <- [sync: sync, async: async] do
      IO.puts "Running #{inspect name}..."
      {
        name,
        1..parsed[:reps] |> Enum.map(strategy)
      }
    end
  end

  defp print_results(named_results) do
    IO.puts ""
    averages = for {name, results} <- named_results do
      IO.inspect name
      average = round average(results)
      IO.puts "\taverage out of #{length results} trials: #{average} reqs/sec"
      {name, average}
    end
    IO.puts ""
    ratio = averages[:sync]/averages[:async]
    IO.puts "ratio of sync:async ->\t#{ratio}"

    named_results
  end

  defp average(list) do
    Enum.reduce(list, 0, &(&1+&2))/length(list)
  end
end
