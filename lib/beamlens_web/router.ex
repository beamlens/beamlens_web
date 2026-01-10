defmodule BeamlensWeb.Router do
  @moduledoc """
  Provides the `live_beamlens_dashboard/2` macro for mounting the BeamLens dashboard.

  ## Usage

      import BeamlensWeb.Router

      scope "/" do
        pipe_through :browser
        live_beamlens_dashboard "/dashboard"
      end
  """

  @doc """
  Defines a route to mount the BeamLens dashboard at the given path.

  ## Options

    * `:live_socket_path` - The path to the LiveView socket. Defaults to `/live`.
    * `:on_mount` - Additional `on_mount` hooks to run. Defaults to `[]`.

  ## Examples

      live_beamlens_dashboard "/dashboard"

      live_beamlens_dashboard "/admin/beamlens",
        on_mount: [{MyApp.Auth, :ensure_admin}]
  """
  defmacro live_beamlens_dashboard(path, opts \\ []) do
    opts =
      if Macro.quoted_literal?(opts) do
        Macro.prewalk(opts, &expand_alias(&1, __CALLER__))
      else
        opts
      end

    quote bind_quoted: binding() do
      scope path, alias: false, as: false do
        import Phoenix.LiveView.Router, only: [live: 3, live: 4, live_session: 2, live_session: 3]

        on_mount = Keyword.get(opts, :on_mount, [])

        live_session :beamlens_dashboard,
          root_layout: {BeamlensWeb.Layouts, :root},
          on_mount: on_mount do
          live("/", BeamlensWeb.DashboardLive, :home)
        end
      end
    end
  end

  defp expand_alias({:__aliases__, _, _} = alias, env),
    do: Macro.expand(alias, %{env | function: {:live_beamlens_dashboard, 2}})

  defp expand_alias(other, _env), do: other
end
