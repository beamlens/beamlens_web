defmodule TestApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      TestAppWeb.Endpoint,
      {Beamlens.Supervisor, []},
      BeamlensWeb.Application
    ]

    opts = [strategy: :one_for_one, name: TestApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
