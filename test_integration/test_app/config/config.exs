import Config

config :test_app, TestAppWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  http: [ip: {127, 0, 0, 1}, port: 4000],
  secret_key_base: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ab",
  debug_errors: true,
  pubsub_server: TestApp.PubSub,
  live_view: [signing_salt: "test_live_view_salt"]

config :phoenix, :json_library, Jason
config :phoenix, :template_engines, phoenix_live_view: Phoenix.LiveView.Engine

config :phoenix_live_view,
  debug_heex_annotations: true,
  debug_attributes: true
