defmodule BeamlensWeb.ScopedAssetPathsTest do
  @moduledoc """
  Integration tests verifying CSS/JS asset paths resolve correctly
  when beamlens_web is mounted under various router scopes.

  Reproduces https://github.com/beamlens/beamlens_web/issues/2
  """
  use ExUnit.Case
  import Plug.Test
  require Phoenix.LiveViewTest

  # ── Test routers ───────────────────────────────────────────────────────

  defmodule RootScopeRouter do
    @moduledoc false
    use Phoenix.Router
    import BeamlensWeb.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
    end

    scope "/" do
      pipe_through(:browser)
      beamlens_web("/beamlens")
    end
  end

  defmodule DevScopeRouter do
    @moduledoc false
    use Phoenix.Router
    import BeamlensWeb.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
    end

    scope "/dev" do
      pipe_through(:browser)
      beamlens_web("/beamlens")
    end
  end

  defmodule DeepScopeRouter do
    @moduledoc false
    use Phoenix.Router
    import BeamlensWeb.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
    end

    scope "/admin/tools" do
      pipe_through(:browser)
      beamlens_web("/beamlens")
    end
  end

  # ── Helpers ────────────────────────────────────────────────────────────

  @session_opts Plug.Session.init(
                  store: :cookie,
                  key: "_test",
                  signing_salt: "test_salt"
                )

  defp call(router, method, path) do
    conn(method, path)
    |> Map.put(:secret_key_base, String.duplicate("a", 64))
    |> Plug.Session.call(@session_opts)
    |> Plug.Conn.fetch_session()
    |> router.call(router.init([]))
  end

  defp extract_asset_paths(html) do
    Regex.scan(~r/(?:href|src)="([^"]*_beamlens_web[^"]*)"/, html)
    |> Enum.map(fn [_full, path] -> path end)
  end

  defp render_layout_with_prefix(prefix) do
    Application.put_env(:beamlens_web, :asset_prefix, prefix)

    Phoenix.LiveViewTest.render_component(&BeamlensWeb.Layouts.root/1, inner_content: "")
  end

  # ── Tests: route matching ──────────────────────────────────────────────

  describe "scope \"/\" with beamlens_web(\"/beamlens\")" do
    test "CSS asset route returns 200" do
      css_hash = BeamlensWeb.Assets.current_hash(:css)
      conn = call(RootScopeRouter, :get, "/_beamlens_web/css-#{css_hash}")
      assert conn.status == 200
      assert {"content-type", "text/css"} in conn.resp_headers
    end

    test "layout produces absolute asset paths matching routes" do
      html = render_layout_with_prefix("/_beamlens_web")
      asset_paths = extract_asset_paths(html)
      assert length(asset_paths) > 0

      for path <- asset_paths do
        assert String.starts_with?(path, "/_beamlens_web/"),
               "Expected absolute path starting with /_beamlens_web/, got: #{path}"

        conn = call(RootScopeRouter, :get, path)

        assert conn.status == 200,
               "Asset at #{path} returned #{conn.status}"
      end
    end
  end

  describe "scope \"/dev\" with beamlens_web(\"/beamlens\") — issue #2" do
    test "CSS asset route returns 200 at /dev/_beamlens_web/*" do
      css_hash = BeamlensWeb.Assets.current_hash(:css)
      conn = call(DevScopeRouter, :get, "/dev/_beamlens_web/css-#{css_hash}")
      assert conn.status == 200
      assert {"content-type", "text/css"} in conn.resp_headers
    end

    test "all JS asset routes return 200 under /dev scope" do
      phoenix_hash = BeamlensWeb.Assets.current_hash(:phoenix_js)
      lv_hash = BeamlensWeb.Assets.current_hash(:live_view_js)
      app_hash = BeamlensWeb.Assets.current_hash(:app_js)

      for {name, hash} <- [
            {"phoenix", phoenix_hash},
            {"live_view", lv_hash},
            {"app", app_hash}
          ] do
        conn = call(DevScopeRouter, :get, "/dev/_beamlens_web/#{name}-#{hash}")
        assert conn.status == 200, "#{name} JS asset returned #{conn.status}"
      end
    end

    test "layout produces correct absolute paths for /dev scope" do
      html = render_layout_with_prefix("/dev/_beamlens_web")
      asset_paths = extract_asset_paths(html)
      assert length(asset_paths) > 0

      for path <- asset_paths do
        assert String.starts_with?(path, "/dev/_beamlens_web/"),
               "Expected path starting with /dev/_beamlens_web/, got: #{path}"

        conn = call(DevScopeRouter, :get, path)

        assert conn.status == 200,
               "Asset at #{path} returned #{conn.status}"
      end
    end

    test "static files (favicon) resolve under /dev scope" do
      conn = call(DevScopeRouter, :get, "/dev/_beamlens_web/favicon.ico")
      assert conn.status == 200
    end
  end

  describe "scope \"/admin/tools\" with beamlens_web(\"/beamlens\") — deep scope" do
    test "layout produces correct absolute paths for deep scope" do
      html = render_layout_with_prefix("/admin/tools/_beamlens_web")
      asset_paths = extract_asset_paths(html)
      assert length(asset_paths) > 0

      for path <- asset_paths do
        assert String.starts_with?(path, "/admin/tools/_beamlens_web/"),
               "Expected path starting with /admin/tools/_beamlens_web/, got: #{path}"

        conn = call(DeepScopeRouter, :get, path)

        assert conn.status == 200,
               "Asset at #{path} returned #{conn.status}"
      end
    end
  end

  # ── Tests: prefix is set by router macro at compile time ─────────────

  describe "asset prefix set by router macro" do
    test "last compiled router sets the asset prefix" do
      # The DeepScopeRouter is the last to compile, so it wins.
      # In production there's only one mount, so this is fine.
      prefix = Application.get_env(:beamlens_web, :asset_prefix)
      assert is_binary(prefix)
      assert String.contains?(prefix, "_beamlens_web")
    end
  end
end
