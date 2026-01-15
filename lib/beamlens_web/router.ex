defmodule BeamlensWeb.Router do
  @moduledoc """
  Provides the `beamlens_web/2` macro for mounting the BeamLens dashboard.

  ## Usage

      import BeamlensWeb.Router

      scope "/" do
        pipe_through :browser
        beamlens_web "/dashboard"
      end
  """


  @doc """
  Defines a route to mount the BeamLens dashboard at the given path.

  ## Options

    * `:live_socket_path` - The path to the LiveView socket. Defaults to `/live`.
    * `:on_mount` - Additional `on_mount` hooks to run. Defaults to `[]`.

  ## Examples

      beamlens_web "/dashboard"

      beamlens_web "/admin/beamlens",
        on_mount: [{MyApp.Auth, :ensure_admin}]
  """
  defmacro beamlens_web(path, opts \\ []) do
    opts =
      if Macro.quoted_literal?(opts) do
        Macro.prewalk(opts, &expand_alias(&1, __CALLER__))
      else
        opts
      end

    quote bind_quoted: binding() do
      import Phoenix.Router, only: [get: 4, forward: 3, scope: 3]

      # Serve embedded CSS asset with cache-busting hash
      get "/_beamlens_web/css-:md5", BeamlensWeb.Assets, :css, as: :beamlens_web_asset

      # Serve static assets (images, favicons) from priv/static
      forward "/_beamlens_web", Plug.Static,
        at: "/",
        from: {:beamlens_web, "priv/static"},
        only: ~w(images favicon.ico favicon-16.png favicon-32.png)

      scope path, alias: false, as: false do
        import Phoenix.LiveView.Router, only: [live: 3, live: 4, live_session: 2, live_session: 3]

        on_mount = Keyword.get(opts, :on_mount, [])

        live_session :beamlens_web,
          root_layout: {BeamlensWeb.Layouts, :root},
          on_mount: on_mount do
          live("/", BeamlensWeb.DashboardLive, :home)
        end
      end
    end
  end

  defp expand_alias({:__aliases__, _, _} = alias, env),
    do: Macro.expand(alias, %{env | function: {:beamlens_web, 2}})

  defp expand_alias(other, _env), do: other
end
