defmodule TestApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :test_app,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      listeners: [Phoenix.CodeReloader],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :os_mon],
      mod: {TestApp.Application, []}
    ]
  end

  defp deps do
    beamlens_web_dep =
      if System.get_env("HEX_RELEASE") do
        {:beamlens_web, "~> 0.1.0-beta.1"}
      else
        {:beamlens_web, path: "../../"}
      end

    [
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:bandit, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:beamlens, "~> 0.2"},
      beamlens_web_dep,
      {:tidewave, "~> 0.5", only: :dev}
    ]
  end
end
