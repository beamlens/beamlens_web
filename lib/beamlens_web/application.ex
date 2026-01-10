defmodule BeamlensWeb.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BeamlensWeb.AlertStore,
      BeamlensWeb.InsightStore,
      BeamlensWeb.EventStore
    ]

    opts = [strategy: :one_for_one, name: BeamlensWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
