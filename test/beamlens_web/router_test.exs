defmodule BeamlensWeb.RouterTest do
  use ExUnit.Case

  test "beamlens_web macro expands without error" do
    # The router macro should compile without requiring configuration
    assert Code.ensure_loaded?(BeamlensWeb.Router)
  end
end
