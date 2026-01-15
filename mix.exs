defmodule BeamlensWeb.MixProject do
  use Mix.Project

  @version "0.1.0"

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
      source_url: "https://github.com/beamlens/beamlens_web"
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
      files: ~w(lib priv/static .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {BeamlensWeb.Application, []}
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
      {:beamlens, "~> 0.2"}
    ]
  end
end
