defmodule BeamlensWeb.LayoutsTest do
  use ExUnit.Case
  require Phoenix.LiveViewTest

  alias BeamlensWeb.Layouts

  setup do
    theme = Application.fetch_env(:beamlens_web, :theme)

    on_exit(fn ->
      case theme do
        {:ok, value} -> Application.put_env(:beamlens_web, :theme, value)
        :error -> Application.delete_env(:beamlens_web, :theme)
      end
    end)
  end

  test "root layout uses asset prefix for all asset paths" do
    Application.put_env(:beamlens_web, :asset_prefix, "/test/_beamlens_web")

    html = Phoenix.LiveViewTest.render_component(&Layouts.root/1, inner_content: "")

    assert html =~ ~s(href="/test/_beamlens_web/css-)
    assert html =~ ~s(src="/test/_beamlens_web/phoenix-)
    assert html =~ ~s(src="/test/_beamlens_web/live_view-)
    assert html =~ ~s(src="/test/_beamlens_web/app-)
    assert html =~ ~s(href="/test/_beamlens_web/favicon.ico")
  after
    Application.delete_env(:beamlens_web, :asset_prefix)
  end

  test "root layout falls back to /_beamlens_web when no prefix configured" do
    Application.delete_env(:beamlens_web, :asset_prefix)

    html = Phoenix.LiveViewTest.render_component(&Layouts.root/1, inner_content: "")

    assert html =~ ~s(href="/_beamlens_web/css-)
    assert html =~ ~s(src="/_beamlens_web/phoenix-)
  end

  test "root layout defaults to system mode" do
    Application.delete_env(:beamlens_web, :theme)

    html = Phoenix.LiveViewTest.render_component(&Layouts.root/1, inner_content: "")

    assert html =~ ~s(data-theme="beamlens-dark")
    assert html =~ ~s(data-theme-mode="system")
    refute html =~ "data-beamlens-theme-overrides"
  end

  test "root layout applies the configured default theme and CSS overrides" do
    Application.put_env(:beamlens_web, :theme,
      default: :light,
      light: %{"--color-primary" => "#3e64ff"},
      css: "@font-face { font-family: Inter; }"
    )

    html = Phoenix.LiveViewTest.render_component(&Layouts.root/1, inner_content: "")

    assert html =~ ~s(data-theme="beamlens-light")
    assert html =~ ~s(data-theme-mode="light")
    assert html =~ "data-beamlens-theme-overrides"
    assert html =~ ~s([data-theme="beamlens-light"] { --color-primary: #3e64ff; })
    assert html =~ "@font-face { font-family: Inter; }"
    assert html =~ ~s(const configured = "light")
  end

  test "root layout renders a dark default before scripts run" do
    Application.put_env(:beamlens_web, :theme, default: :dark)

    html = Phoenix.LiveViewTest.render_component(&Layouts.root/1, inner_content: "")

    assert html =~ ~s(data-theme="beamlens-dark")
    assert html =~ ~s(data-theme-mode="dark")
    assert html =~ ~s(const configured = "dark")
  end
end
