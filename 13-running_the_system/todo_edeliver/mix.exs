defmodule Todo.Mixfile do
  use Mix.Project

  def project do
    [app: :todo,
     version: "0.0.1",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [
      applications: [
        :logger,
        :gproc,
        :cowboy,
        :plug,
        :mnesia,
        :runtime_tools,
        :edeliver,
      ],
      mod: {Todo.Application, []},
    ]
  end

  defp deps do
    [
      {:gproc, "0.6.1"},
      {:cowboy, "1.1.2"},
      {:plug, "1.3.4"},
      {:edeliver, "1.4.2"},
      {:distillery, "1.3.4", warn_missing: false},
    ]
  end
end
