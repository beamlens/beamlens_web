defmodule BeamlensWeb.MixProject do
  use Mix.Project

  def project do
    [
      app: :beamlens_web,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:req, "~> 0.5"},
      {:beamlens, path: "../beamlens"}
    ]
  end
end
