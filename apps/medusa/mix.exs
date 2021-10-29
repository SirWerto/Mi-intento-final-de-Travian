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
      extra_applications: [:logger],
      mod: {Medusa.Application, []}
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:gen_stage, "~> 1.0"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:propcheck, "~> 1.4", only: [:test, :dev]},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:t_db, in_umbrella: true}
    ]
  end
end
