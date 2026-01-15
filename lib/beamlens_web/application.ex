defmodule BeamlensWeb.Application do
  @moduledoc """
  Application module for BeamlensWeb.

  This module implements the Application behaviour and provides
  a child_spec/1 function to allow it to be included in a
  host application's supervision tree.

  ## Example

  In your application's children list:

  ```elixir
  children = [
    BeamlensWeb.Application
  ]
  ```
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BeamlensWeb.NotificationStore,
      BeamlensWeb.InsightStore,
      BeamlensWeb.EventStore
    ]

    opts = [strategy: :one_for_one, name: BeamlensWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Returns a child specification for embedding this application in a supervision tree.

  This allows BeamlensWeb.Application to be used as a child in another
  application's supervision tree.

  ## Example

  ```elixir
  children = [
    BeamlensWeb.Application
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
