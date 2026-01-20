defmodule BeamlensWeb.Application do
  @moduledoc """
  Application module for BeamlensWeb.

  This module implements the Application behaviour and provides
  a child_spec/1 function to allow it to be included in a
  host application's supervision tree.

  ## Example

  Basic usage (no AI summaries):

  ```elixir
  children = [
    BeamlensWeb
  ]
  ```

  With AI-powered summaries (optional):

  ```elixir
  children = [
    {BeamlensWeb, client_registry: %{primary: "MyClient", clients: [...]}}
  ]
  ```

  ## Options

    * `:client_registry` - (optional) A map containing LLM client configuration with keys:
      * `:primary` - The name of the primary client to use
      * `:clients` - A list of client configurations with `:name`, `:provider`, and `:options`

  When `client_registry` is not provided, the chat interface displays raw analysis
  data instead of AI-generated summaries.
  """

  use Application

  @impl true
  def start(_type, opts) do
    children = [
      {BeamlensWeb.Config, opts},
      {Task.Supervisor, name: BeamlensWeb.TaskSupervisor},
      BeamlensWeb.NotificationStore,
      BeamlensWeb.InsightStore,
      BeamlensWeb.EventStore
    ]

    sup_opts = [strategy: :one_for_one, name: BeamlensWeb.Supervisor]
    Supervisor.start_link(children, sup_opts)
  end

  @doc """
  Returns a child specification for embedding this application in a supervision tree.

  This allows BeamlensWeb to be used as a child in another
  application's supervision tree with runtime configuration.

  ## Example

  ```elixir
  children = [
    BeamlensWeb
  ]
  ```

  Or with AI-powered summaries:

  ```elixir
  children = [
    {BeamlensWeb, client_registry: %{primary: "MyClient", clients: [...]}}
  ]
  ```
  """
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start, [:normal, opts]},
      type: :supervisor,
      restart: :permanent,
      shutdown: 5000
    }
  end
end
