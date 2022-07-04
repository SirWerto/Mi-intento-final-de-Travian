defmodule Medusa.MixProject do
  use Mix.Project

  def project do
    [
      app: :medusa,
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

  def application do
    [
      extra_applications: [:logger, :collector],
      mod: {Medusa.Application, []}
    ]
  end

  defp deps do
    [
      {:gen_stage, "~> 1.0"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:propcheck, "~> 1.4", only: [:test, :dev]},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:t_types, in_umbrella: true},
      {:storage, in_umbrella: true},
      {:satellite, in_umbrella: true},
      {:collector, in_umbrella: true}
    ]
  end
end
