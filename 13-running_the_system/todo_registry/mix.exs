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
        :cowboy,
        :plug,
        :mnesia,
      ],
      mod: {Todo.Application, []},
    ]
  end

  defp deps do
    [
      {:cowboy, "1.1.2"},
      {:plug, "1.3.4"},
      {:distillery, "1.3.4"},
    ]
  end
end
