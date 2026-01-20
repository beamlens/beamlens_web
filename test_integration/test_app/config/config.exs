import Config

config :test_app, TestAppWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  http: [ip: {127, 0, 0, 1}, port: 4000],
  secret_key_base: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ab",
  debug_errors: true,
  pubsub_server: TestApp.PubSub,
  reloadable_apps: [:test_app, :beamlens_web],
  live_view: [signing_salt: "test_live_view_salt"],
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/test_app_web/(?:controllers|live|components|router)/?.*\.(ex|heex)$",
      ~r"lib/beamlens_web/.*\.(ex|heex)$"
    ]
  ]

config :phoenix, :json_library, Jason
config :phoenix, :template_engines, phoenix_live_view: Phoenix.LiveView.Engine
config :phoenix_live_reload, :dirs, ["", "../../"]

config :phoenix_live_view,
  debug_heex_annotations: true,
  debug_attributes: true
