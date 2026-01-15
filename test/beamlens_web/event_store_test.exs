defmodule BeamlensWeb.EventStoreTest do
  use ExUnit.Case
  alias BeamlensWeb.EventStore

  # Note: EventStore is started by the Application supervisor
  # Tests run against the globally started process

  setup do
    # Clean up ETS table before each test
    :ets.delete_all_objects(:beamlens_web_events)
    :ok
  end

  describe "start_link/1" do
    test "starts the EventStore GenServer" do
      assert Process.whereis(EventStore) != nil
    end
  end

  describe "list_events/1" do
    test "returns empty list when no events" do
      assert EventStore.list_events() == []
    end

    test "returns all events sorted by timestamp (newest first)" do
      now = DateTime.utc_now()
      earlier = DateTime.add(now, -1, :second)

      emit_event([:beamlens, :operator, :iteration_start], %{
        system_time: DateTime.to_unix(earlier, :native)
      }, %{operator: :op1, iteration: 1})

      emit_event([:beamlens, :operator, :state_change], %{
        system_time: DateTime.to_unix(now, :native)
      }, %{operator: :op1, from: :idle, to: :running})

      events = EventStore.list_events()
      assert length(events) == 2
      assert hd(events).event_type == :state_change
      assert List.last(events).event_type == :iteration_start
    end

    test "filters events by source" do
      emit_event([:beamlens, :operator, :iteration_start], %{
        system_time: DateTime.to_unix(DateTime.utc_now(), :native)
      }, %{operator: :op1, iteration: 1})

      emit_event([:beamlens, :coordinator, :iteration_start], %{
        system_time: DateTime.to_unix(DateTime.utc_now(), :native)
      }, %{iteration: 1, notification_count: 0})

      op_events = EventStore.list_events(:op1)
      coordinator_events = EventStore.list_events(:coordinator)

      assert length(op_events) == 1
      assert length(coordinator_events) == 1
      assert hd(op_events).source == :op1
      assert hd(coordinator_events).source == :coordinator
    end
  end

  describe "count/0" do
    test "returns 0 when no events" do
      assert EventStore.count() == 0
    end

    test "returns count of stored events" do
      emit_event([:beamlens, :operator, :iteration_start], %{
        system_time: DateTime.to_unix(DateTime.utc_now(), :native)
      }, %{operator: :op1, iteration: 1})

      emit_event([:beamlens, :operator, :state_change], %{
        system_time: DateTime.to_unix(DateTime.utc_now(), :native)
      }, %{operator: :op1, from: :idle, to: :running})

      assert EventStore.count() == 2
    end
  end

  describe "events_callback/1" do
    test "returns events callback data" do
      emit_event([:beamlens, :operator, :iteration_start], %{
        system_time: DateTime.to_unix(DateTime.utc_now(), :native)
      }, %{operator: :op1, iteration: 1})

      events = EventStore.events_callback()
      assert length(events) == 1
    end
  end

  describe "handle_telemetry_event/4" do
    test "stores operator iteration_start event" do
      emit_event([:beamlens, :operator, :iteration_start], %{
        system_time: DateTime.to_unix(DateTime.utc_now(), :native)
      }, %{operator: :test_op, iteration: 5, operator_state: :running})

      [event] = EventStore.list_events()
      assert event.event_type == :iteration_start
      assert event.source == :test_op
      assert event.metadata.iteration == 5
      assert event.metadata.operator_state == :running
    end

    test "stores operator state_change event" do
      emit_event([:beamlens, :operator, :state_change], %{
        system_time: DateTime.to_unix(DateTime.utc_now(), :native)
      }, %{operator: :test_op, from: :idle, to: :running, reason: :auto_start})

      [event] = EventStore.list_events()
      assert event.event_type == :state_change
      assert event.metadata.from == :idle
      assert event.metadata.to == :running
      assert event.metadata.reason == :auto_start
    end

    test "stores coordinator insight_produced event" do
      notification = build_notification("notif-1")
      insight = build_insight("insight-1", [notification.id])

      emit_event([:beamlens, :coordinator, :insight_produced], %{
        system_time: DateTime.to_unix(DateTime.utc_now(), :native)
      }, %{insight: insight})

      [event] = EventStore.list_events()
      assert event.event_type == :insight_produced
      assert event.source == :coordinator
      assert event.metadata.insight_id == "insight-1"
      assert event.metadata.correlation_type == :temporal
    end
  end

  # Helper functions

  defp emit_event(event_name, measurements, metadata) do
    :telemetry.execute(event_name, measurements, metadata)
    # Small delay to ensure async processing
    Process.sleep(10)
  end

  defp build_notification(id) do
    %{
      id: id,
      operator: :test_op,
      anomaly_type: :error_spike,
      severity: :critical,
      summary: "Test notification",
      snapshots: [],
      detected_at: DateTime.utc_now(),
      node: :node@host,
      trace_id: "trace-1"
    }
  end

  defp build_insight(id, notification_ids) do
    %{
      id: id,
      notification_ids: notification_ids,
      correlation_type: :temporal,
      summary: "Test insight",
      root_cause_hypothesis: "Test hypothesis",
      confidence: :high,
      created_at: DateTime.utc_now()
    }
  end
end
