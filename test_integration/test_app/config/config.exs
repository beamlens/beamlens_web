import Config

config :test_app, TestAppWeb.Endpoint,
  url: [host: "localhost"],
  http: [ip: {127, 0, 0, 1}, port: 4000],
  secret_key_base: "test_secret_key_base_for_integration_testing",
  render_errors: [view: TestAppWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: TestApp.PubSub

config :phoenix, :json_library, Jason
config :phoenix, :template_engines, phoenix_live_view: Phoenix.LiveView.Engine
