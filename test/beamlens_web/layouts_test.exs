defmodule BeamlensWeb.LayoutsTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias BeamlensWeb.Layouts

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
end
