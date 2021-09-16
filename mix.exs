defmodule MyTravian.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false}
    ]
  end

  defp releases do
    [
      collector: release_collector()
    ]
  end


  defp release_collector do
    [
      applications: [
	kernel: :permanent,
	stdlib: :permanent,
	sasl: :permanent,
	elixir: :permanent,
	t_db: :permanent,
	collector: :permanent
      ],
      include_executables_for: [:unix],
      steps: [:assemble, :tar]
    ]
  end
end
