defmodule TestApp.Application do
  use Application

  def start(_type, _args) do
    client_registry = build_client_registry()

    children = [
      {Phoenix.PubSub, name: TestApp.PubSub},
      TestAppWeb.Endpoint,
      {Beamlens, client_registry: client_registry},
      {BeamlensWeb, client_registry: client_registry}
    ]

    opts = [strategy: :one_for_one, name: TestApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp build_client_registry do
    case System.get_env("ANTHROPIC_API_KEY") do
      nil ->
        %{}

      api_key ->
        %{
          primary: "Anthropic",
          clients: [
            %{
              name: "Anthropic",
              provider: "anthropic",
              options: %{
                model: System.get_env("ANTHROPIC_MODEL", "claude-haiku-4-5"),
                api_key: api_key
              }
            }
          ]
        }
    end
  end
end
