defmodule BeamlensWeb.Config do
  @moduledoc """
  Stores runtime configuration for BeamlensWeb using persistent_term.

  Configuration is written once at startup and read frequently by the dashboard.
  """

  @doc """
  Starts the config store and writes configuration to persistent_term.

  Returns `:ignore` since no process is needed - configuration is stored in persistent_term.
  """
  def start_link(opts) do
    client_registry = Keyword.get(opts, :client_registry, %{})
    :persistent_term.put({__MODULE__, :client_registry}, client_registry)
    :ignore
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :temporary
    }
  end

  @doc """
  Returns the configured client_registry, or an empty map if not set.
  """
  def client_registry do
    :persistent_term.get({__MODULE__, :client_registry}, %{})
  end

  @doc """
  Returns true if chat/analysis features are enabled (client_registry is configured).
  """
  def chat_enabled? do
    client_registry() != %{}
  end

  @theme_modes [:light, :dark, :system]

  @doc "Returns the default theme mode."
  def theme_default do
    case Keyword.get(theme(), :default, :system) do
      mode when mode in @theme_modes -> mode
      _ -> :system
    end
  end

  @doc "Returns the configured CSS overrides."
  def theme_override_css do
    config = theme()

    [
      variables_block(~s([data-theme="beamlens-light"]), config[:light]),
      variables_block(~s([data-theme="beamlens-dark"]), config[:dark]),
      Keyword.get(config, :css, "")
    ]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  defp theme, do: Application.get_env(:beamlens_web, :theme, [])

  defp variables_block(selector, variables) when is_map(variables) and variables != %{} do
    declarations =
      variables
      |> Enum.sort()
      |> Enum.map_join(" ", fn {name, value} -> "#{name}: #{value};" end)

    "#{selector} { #{declarations} }"
  end

  defp variables_block(_selector, _), do: ""
end
