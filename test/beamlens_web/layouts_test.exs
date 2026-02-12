defmodule BeamlensWeb.LayoutsTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias BeamlensWeb.Layouts

  test "root layout uses scope-aware relative asset paths" do
    html = render_component(&Layouts.root/1, %{inner_content: ""})

    assert html =~ ~s(href="_beamlens_web/css-)
    assert html =~ ~s(src="_beamlens_web/phoenix-)
    assert html =~ ~s(src="_beamlens_web/live_view-)
    assert html =~ ~s(src="_beamlens_web/app-)
    refute html =~ "/_beamlens_web/"
  end
end
