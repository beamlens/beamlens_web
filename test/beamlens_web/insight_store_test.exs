defmodule BeamlensWeb.InsightStoreTest do
  use ExUnit.Case
  alias BeamlensWeb.InsightStore

  # Note: InsightStore is started by the Application supervisor
  # Tests run against the globally started process

  setup do
    # Clean up ETS table before each test
    :ets.delete_all_objects(:beamlens_web_insights)
    :ok
  end

  describe "start_link/1" do
    test "starts the InsightStore GenServer" do
      assert Process.whereis(InsightStore) != nil
    end
  end

  describe "list_insights/0" do
    test "returns empty list when no insights" do
      assert InsightStore.list_insights() == []
    end

    test "returns all insights sorted by created_at (newest first)" do
      now = DateTime.utc_now()
      earlier = DateTime.add(now, -1, :second)

      emit_insight(earlier, "insight-1")
      Process.sleep(10)
      emit_insight(now, "insight-2")

      insights = InsightStore.list_insights()
      assert length(insights) == 2
      assert DateTime.compare(hd(insights).created_at, List.last(insights).created_at) == :gt
    end
  end

  describe "count/0" do
    test "returns 0 when no insights" do
      assert InsightStore.count() == 0
    end

    test "returns count of stored insights" do
      emit_insight(DateTime.utc_now(), "insight-1")
      emit_insight(DateTime.utc_now(), "insight-2")

      assert InsightStore.count() == 2
    end
  end

  describe "get_insight/1" do
    test "returns insight when found" do
      now = DateTime.utc_now()
      emit_insight(now, "test-id")

      assert {:ok, insight} = InsightStore.get_insight("test-id")
      assert insight.id == "test-id"
      assert insight.correlation_type == :temporal
    end

    test "returns error when not found" do
      assert {:error, :not_found} = InsightStore.get_insight("nonexistent")
    end
  end

  describe "insights_callback/0" do
    test "returns insights callback data" do
      emit_insight(DateTime.utc_now(), "insight-1")

      insights = InsightStore.insights_callback()
      assert length(insights) == 1
    end
  end

  describe "handle_telemetry_event/4" do
    test "stores insight with correct fields" do
      now = DateTime.utc_now()
      notification_id = "notif-1"

      emit_insight(now, "insight-1", [notification_id])

      [insight] = InsightStore.list_insights()
      assert insight.id == "insight-1"
      assert insight.correlation_type == :temporal
      assert insight.summary == "Test insight"
      assert insight.root_cause_hypothesis == "Test hypothesis"
      assert insight.confidence == :high
      assert insight.notification_ids == [notification_id]
    end
  end

  # Helper functions

  defp emit_insight(created_at, id, notification_ids \\ nil) do
    insight = %{
      id: id,
      notification_ids: notification_ids || ["notif-1"],
      correlation_type: :temporal,
      summary: "Test insight",
      root_cause_hypothesis: "Test hypothesis",
      confidence: :high,
      created_at: created_at
    }

    :telemetry.execute(
      [:beamlens, :coordinator, :insight_produced],
      %{system_time: DateTime.to_unix(created_at, :native)},
      %{insight: insight}
    )

    Process.sleep(10)
  end
end
