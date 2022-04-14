defmodule Collector.MixProject do
  use Mix.Project

  def project do
    [
      app: :collector,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Collector.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:finch, "~> 0.8"},
      {:floki, "~> 0.31.0"},
      {:jason, "~> 1.2"},
      {:travianmap, "~> 0.3.0"},
      {:t_types, in_umbrella: true},
      {:storage, in_umbrella: true}
      # {:medusa, in_umbrella: true}
    ]
  end
end
