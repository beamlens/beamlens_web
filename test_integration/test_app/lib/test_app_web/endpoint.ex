defmodule TestAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :test_app

  @session_options [
    store: :cookie,
    key: "_test_app_key",
    signing_salt: "test_signing_salt",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket

  if Code.ensure_loaded?(Tidewave) do
    plug(Tidewave)
  end

  plug(Phoenix.LiveReloader)

  plug(Plug.Static,
    at: "/",
    from: :beamlens_web,
    gzip: false,
    only: ~w(assets images favicon.ico favicon-16.png favicon-32.png)
  )

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(TestAppWeb.Router)
end
