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
end
