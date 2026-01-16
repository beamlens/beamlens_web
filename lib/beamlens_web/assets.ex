defmodule BeamlensWeb.Assets do
  @moduledoc false
  import Plug.Conn

  css_path = Path.join(__DIR__, "../../priv/static/assets/app.css")
  @external_resource css_path
  @css File.read!(css_path)

  phoenix_js_path = Path.join(__DIR__, "../../priv/static/assets/js/phoenix.min.js")
  @external_resource phoenix_js_path
  @phoenix_js File.read!(phoenix_js_path)

  live_view_js_path = Path.join(__DIR__, "../../priv/static/assets/js/phoenix_live_view.min.js")
  @external_resource live_view_js_path
  @live_view_js File.read!(live_view_js_path)

  app_js_path = Path.join(__DIR__, "../../priv/static/assets/js/app.js")
  @external_resource app_js_path
  @app_js File.read!(app_js_path)

  @hashes %{
    css: Base.encode16(:crypto.hash(:md5, @css), case: :lower),
    phoenix_js: Base.encode16(:crypto.hash(:md5, @phoenix_js), case: :lower),
    live_view_js: Base.encode16(:crypto.hash(:md5, @live_view_js), case: :lower),
    app_js: Base.encode16(:crypto.hash(:md5, @app_js), case: :lower)
  }

  def init(asset) when asset in [:css, :phoenix_js, :live_view_js, :app_js], do: asset

  def call(conn, asset) do
    {contents, content_type} = contents_and_type(asset)

    conn
    |> put_resp_header("content-type", content_type)
    |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
    |> put_private(:plug_skip_csrf_protection, true)
    |> send_resp(200, contents)
    |> halt()
  end

  defp contents_and_type(:css), do: {@css, "text/css"}
  defp contents_and_type(:phoenix_js), do: {@phoenix_js, "application/javascript"}
  defp contents_and_type(:live_view_js), do: {@live_view_js, "application/javascript"}
  defp contents_and_type(:app_js), do: {@app_js, "application/javascript"}

  @doc """
  Returns the current hash for the given asset.
  """
  def current_hash(:css), do: @hashes.css
  def current_hash(:phoenix_js), do: @hashes.phoenix_js
  def current_hash(:live_view_js), do: @hashes.live_view_js
  def current_hash(:app_js), do: @hashes.app_js
end
