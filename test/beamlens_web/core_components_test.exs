defmodule BeamlensWeb.CoreComponentsTest do
  use ExUnit.Case, async: true

  alias BeamlensWeb.CoreComponents

  describe "format_datetime/1" do
    test "formats DateTime" do
      dt = DateTime.from_naive!(~N[2024-01-15 14:30:00], "Etc/UTC")
      assert CoreComponents.format_datetime(dt) == "2024-01-15 14:30:00"
    end

    test "returns dash for nil" do
      assert CoreComponents.format_datetime(nil) == "-"
    end

    test "returns inspect for other types" do
      assert CoreComponents.format_datetime("invalid") == ~s("invalid")
    end
  end

  describe "format_relative/1" do
    test "formats time seconds ago" do
      dt = DateTime.utc_now() |> DateTime.add(-30, :second)
      assert CoreComponents.format_relative(dt) =~ "s ago"
    end

    test "formats time minutes ago" do
      dt = DateTime.utc_now() |> DateTime.add(-300, :second)
      assert CoreComponents.format_relative(dt) =~ "m ago"
    end

    test "formats time hours ago" do
      dt = DateTime.utc_now() |> DateTime.add(-7200, :second)
      assert CoreComponents.format_relative(dt) =~ "h ago"
    end

    test "formats time days ago" do
      dt = DateTime.utc_now() |> DateTime.add(-100000, :second)
      assert CoreComponents.format_relative(dt) =~ "d ago"
    end

    test "returns dash for nil" do
      assert CoreComponents.format_relative(nil) == "-"
    end
  end

  describe "format_node_name/1" do
    test "extracts hostname from node@host format" do
      assert CoreComponents.format_node_name(:node@host) == "node"
    end

    test "returns node name when no host" do
      assert CoreComponents.format_node_name(:node) == "node"
    end

    test "handles string input" do
      assert CoreComponents.format_node_name("node@host") == "node@host"
    end
  end
end
