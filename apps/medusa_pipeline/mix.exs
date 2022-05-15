defmodule MedusaPipeline.MixProject do
  use Mix.Project

  def project do
    [
      app: :medusa_pipeline,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :collector]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:propcheck, "~> 1.4", only: [:test, :dev]},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:collector, in_umbrella: true},
      {:storage, in_umbrella: true},
      {:t_types, in_umbrella: true}
    ]
  end
end
