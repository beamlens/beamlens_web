defmodule BeamlensWeb.NotificationStoreTest do
  use ExUnit.Case
  alias BeamlensWeb.NotificationStore

  # Note: NotificationStore is started by the Application supervisor
  # Tests run against the globally started process

  setup do
    # Clean up ETS table before each test
    :ets.delete_all_objects(:beamlens_web_notifications)
    :ok
  end

  describe "start_link/1" do
    test "starts the NotificationStore GenServer" do
      assert Process.whereis(NotificationStore) != nil
    end
  end

  describe "list_notifications/1" do
    test "returns empty list when no notifications" do
      assert NotificationStore.list_notifications() == []
    end

    test "returns all notifications sorted by detected_at (newest first)" do
      now = DateTime.utc_now()
      earlier = DateTime.add(now, -1, :second)

      emit_notification(earlier)
      Process.sleep(10)
      emit_notification(now)

      notifications = NotificationStore.list_notifications()
      assert length(notifications) == 2

      assert DateTime.compare(hd(notifications).detected_at, List.last(notifications).detected_at) ==
               :gt
    end

    test "filters notifications by status" do
      now = DateTime.utc_now()

      notif1 = emit_notification(now, "notif-1")
      _notif2 = emit_notification(now, "notif-2")

      # Manually update status
      :ets.insert(
        :beamlens_web_notifications,
        {notif1.id, Map.put(notif1, :status, :acknowledged)}
      )

      all = NotificationStore.list_notifications()
      unread = NotificationStore.list_notifications(:unread)
      acknowledged = NotificationStore.list_notifications(:acknowledged)

      assert length(all) == 2
      assert length(unread) == 1
      assert length(acknowledged) == 1
    end
  end

  describe "counts/0" do
    test "returns zero counts when no notifications" do
      counts = NotificationStore.counts()
      assert counts.total == 0
      assert counts.unread == 0
      assert counts.acknowledged == 0
      assert counts.resolved == 0
    end

    test "returns accurate counts by status" do
      now = DateTime.utc_now()

      notif1 = emit_notification(now, "notif-1")
      notif2 = emit_notification(now, "notif-2")
      notif3 = emit_notification(now, "notif-3")

      # Update statuses
      :ets.insert(:beamlens_web_notifications, {notif1.id, Map.put(notif1, :status, :unread)})

      :ets.insert(
        :beamlens_web_notifications,
        {notif2.id, Map.put(notif2, :status, :acknowledged)}
      )

      :ets.insert(:beamlens_web_notifications, {notif3.id, Map.put(notif3, :status, :resolved)})

      counts = NotificationStore.counts()
      assert counts.total == 3
      assert counts.unread == 1
      assert counts.acknowledged == 1
      assert counts.resolved == 1
    end
  end

  describe "get_notification/1" do
    test "returns notification when found" do
      now = DateTime.utc_now()
      _notification = emit_notification(now, "test-id")

      assert {:ok, found} = NotificationStore.get_notification("test-id")
      assert found.id == "test-id"
      assert found.operator == :test_op
    end

    test "returns error when not found" do
      assert {:error, :not_found} = NotificationStore.get_notification("nonexistent")
    end
  end

  describe "notifications_callback/1" do
    test "returns notifications callback data" do
      emit_notification(DateTime.utc_now(), "notif-1")

      notifications = NotificationStore.notifications_callback()
      assert length(notifications) == 1
    end

    test "filters by status in callback" do
      now = DateTime.utc_now()
      notif1 = emit_notification(now, "notif-1")

      # Update status
      :ets.insert(
        :beamlens_web_notifications,
        {notif1.id, Map.put(notif1, :status, :acknowledged)}
      )

      unread = NotificationStore.notifications_callback(:unread)
      acknowledged = NotificationStore.notifications_callback(:acknowledged)

      assert length(unread) == 0
      assert length(acknowledged) == 1
    end
  end

  describe "notification_counts_callback/0" do
    test "returns counts callback data" do
      emit_notification(DateTime.utc_now(), "notif-1")

      counts = NotificationStore.notification_counts_callback()
      assert counts.total == 1
      assert counts.unread == 1
    end
  end

  # Helper functions

  defp emit_notification(detected_at, id \\ nil) do
    notification = %{
      id: id || "notif-#{System.unique_integer([:positive])}",
      operator: :test_op,
      anomaly_type: :error_spike,
      severity: :critical,
      context: "Test context",
      observation: "Test observation",
      hypothesis: "Test hypothesis",
      snapshots: [],
      detected_at: detected_at,
      node: :node@host,
      trace_id: "trace-1"
    }

    :telemetry.execute(
      [:beamlens, :operator, :notification_sent],
      %{system_time: DateTime.to_unix(detected_at, :native)},
      %{notification: notification}
    )

    Process.sleep(10)
    notification
  end
end
