defmodule BeamlensWeb.ConfigTest do
  use ExUnit.Case
  alias BeamlensWeb.Config

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
