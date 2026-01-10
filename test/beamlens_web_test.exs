defmodule BeamlensWebTest do
  use ExUnit.Case
  doctest BeamlensWeb

  test "application module exists" do
    assert Code.ensure_loaded?(BeamlensWeb)
  end
end
