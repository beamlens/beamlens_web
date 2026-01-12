defmodule BeamlensWeb.Application do
  @moduledoc false

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
end
