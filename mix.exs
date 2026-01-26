defmodule BeamlensWeb.MixProject do
  use Mix.Project

  @version "0.1.0-beta.2"

  def project do
    [
      app: :beamlens_web,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "BeamlensWeb",
      source_url: "https://github.com/beamlens/beamlens_web",
      test_pattern: "**/*_test.exs",
      test_test_paths: ["test"],
      test_ignore_filters: [~r/test\/support\/.*/]
    ]
  end

  defp description do
    "A Phoenix LiveView dashboard for monitoring BeamLens operators and coordinator activity."
  end

  defp package do
    [
      name: "beamlens_web",
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/beamlens/beamlens_web"
      },
      files:
        ~w(lib priv/static priv/baml_src .formatter.exs mix.exs README.md CHANGELOG.md LICENSE)
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_html, "~> 4.0"},
      {:bandit, "~> 1.0", only: :test},
      {:jason, "~> 1.4"},
      {:req, "~> 0.5"},
      {:beamlens, "~> 0.3.0"},
      {:mdex, "~> 0.11"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:igniter, "~> 0.6", only: [:dev, :test], runtime: false}
    ]
  end
end
