defmodule MyTravian.MixProject do
  use Mix.Project

  def project do
    [
      name: "MyTravian project",
      apps_path: "apps",
      version: "0.2.0",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: releases()
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.

  defp aliases do
    [
      ensure: [
        "format --check-formatted",
        "dialyzer",
        "credo"
      ]
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  defp releases do
    [
      imperatoris: release_imperatoris(),
      legati: release_legati(),
      monolith: release_monolith()
    ]
  end

  defp release_imperatoris do
    [
      applications: [
        kernel: :permanent,
        stdlib: :permanent,
        sasl: :permanent,
        elixir: :permanent,
        collector: :permanent,
        medusa: :permanent,
        satellite: :permanent
      ],
      include_executables_for: [:unix],
      steps: [:assemble, :tar]
    ]
  end

  defp release_legati do
    [
      applications: [
        kernel: :permanent,
        stdlib: :permanent,
        sasl: :permanent,
        elixir: :permanent,
        satellite: :permanent,
        front: :permanent
      ],
      include_executables_for: [:unix],
      steps: [:assemble, :tar]
    ]
  end

  defp release_monolith do
    [
      applications: [
        kernel: :permanent,
        stdlib: :permanent,
        sasl: :permanent,
        elixir: :permanent,
        collector: :permanent,
        medusa: :permanent,
        satellite: :permanent,
        front: :permanent
      ],
      include_executables_for: [:unix],
      steps: [:assemble, :tar]
    ]
  end
end
