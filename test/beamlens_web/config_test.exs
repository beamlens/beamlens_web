defmodule BeamlensWeb.ConfigTest do
  use ExUnit.Case
  alias BeamlensWeb.Config

  setup do
    theme = Application.fetch_env(:beamlens_web, :theme)

    on_exit(fn ->
      case theme do
        {:ok, value} -> Application.put_env(:beamlens_web, :theme, value)
        :error -> Application.delete_env(:beamlens_web, :theme)
      end
    end)
  end

  describe "start_link/1" do
    test "stores client_registry in persistent_term" do
      registry = %{primary: "test", clients: []}
      :persistent_term.erase({Config, :client_registry})

      assert :ignore = Config.start_link(client_registry: registry)
      assert :persistent_term.get({Config, :client_registry}) == registry
    end

    test "defaults to empty map when client_registry not provided" do
      :persistent_term.erase({Config, :client_registry})

      assert :ignore = Config.start_link([])
      assert :persistent_term.get({Config, :client_registry}) == %{}
    end
  end

  describe "client_registry/0" do
    test "returns stored value from persistent_term" do
      registry = %{primary: "anthropic", clients: [%{name: "test"}]}
      :persistent_term.put({Config, :client_registry}, registry)

      assert Config.client_registry() == registry
    end

    test "returns empty map when not configured" do
      :persistent_term.erase({Config, :client_registry})

      assert Config.client_registry() == %{}
    end
  end

  describe "theme_default/0" do
    test "defaults to :system when unconfigured" do
      Application.delete_env(:beamlens_web, :theme)
      assert Config.theme_default() == :system
    end

    test "returns the configured mode" do
      for mode <- [:light, :dark, :system] do
        Application.put_env(:beamlens_web, :theme, default: mode)
        assert Config.theme_default() == mode
      end
    end

    test "falls back to :system for invalid values" do
      Application.put_env(:beamlens_web, :theme, default: :neon)
      assert Config.theme_default() == :system
    end
  end

  describe "theme_override_css/0" do
    test "returns an empty string when unconfigured" do
      Application.delete_env(:beamlens_web, :theme)
      assert Config.theme_override_css() == ""
    end

    test "builds data-theme scoped blocks from variable maps" do
      Application.put_env(:beamlens_web, :theme,
        light: %{"--color-primary" => "#3e64ff", "--color-base-100" => "#ffffff"},
        dark: %{"--color-base-100" => "#0d1829"}
      )

      css = Config.theme_override_css()

      assert css =~
               ~s([data-theme="beamlens-light"] { --color-base-100: #ffffff; --color-primary: #3e64ff; })

      assert css =~ ~s([data-theme="beamlens-dark"] { --color-base-100: #0d1829; })
    end

    test "appends raw css after the variable blocks" do
      Application.put_env(:beamlens_web, :theme,
        light: %{"--color-primary" => "#3e64ff"},
        css: "@font-face { font-family: Inter; }"
      )

      css = Config.theme_override_css()
      [variables, raw] = String.split(css, "\n")

      assert variables =~ "beamlens-light"
      assert raw == "@font-face { font-family: Inter; }"
    end

    test "ignores empty variable maps" do
      Application.put_env(:beamlens_web, :theme, light: %{}, dark: %{})
      assert Config.theme_override_css() == ""
    end
  end

  describe "child_spec/1" do
    test "returns valid child spec" do
      spec = Config.child_spec(client_registry: %{})

      assert spec.id == Config
      assert spec.type == :worker
      assert spec.restart == :temporary
      assert {Config, :start_link, [_opts]} = spec.start
    end
  end
end
