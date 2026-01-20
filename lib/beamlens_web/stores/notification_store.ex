defmodule BeamlensWeb.NotificationStore do
  @moduledoc """
  ETS-based store for notifications received from BeamLens operators.

  Subscribes to `[:beamlens, :operator, :notification_sent]` telemetry events
  and stores notifications for display in the dashboard.
  """

  use GenServer

  @table_name :beamlens_web_notifications
  @telemetry_handler_id "beamlens-web-notification-store"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Returns all notifications, optionally filtered by status.
  """
  def list_notifications(status \\ nil) do
    case status do
      nil ->
        :ets.tab2list(@table_name)
        |> Enum.map(fn {_id, notification} -> notification end)
        |> Enum.sort_by(& &1.detected_at, {:desc, DateTime})

      status ->
        :ets.tab2list(@table_name)
        |> Enum.map(fn {_id, notification} -> notification end)
        |> Enum.filter(&(&1.status == status))
        |> Enum.sort_by(& &1.detected_at, {:desc, DateTime})
    end
  end

  @doc """
  Returns counts of notifications by status.
  """
  def counts do
    notifications =
      :ets.tab2list(@table_name) |> Enum.map(fn {_id, notification} -> notification end)

    %{
      total: length(notifications),
      unread: Enum.count(notifications, &(&1.status == :unread)),
      acknowledged: Enum.count(notifications, &(&1.status == :acknowledged)),
      resolved: Enum.count(notifications, &(&1.status == :resolved))
    }
  end

  @doc """
  Gets a single notification by ID.
  """
  def get_notification(id) do
    case :ets.lookup(@table_name, id) do
      [{^id, notification}] -> {:ok, notification}
      [] -> {:error, :not_found}
    end
  end

  @doc false

  def notifications_callback(status \\ nil) do
    list_notifications(status)
  end

  @doc false

  def notification_counts_callback do
    counts()
  end

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:named_table, :set, :public, read_concurrency: true])

    :telemetry.attach(
      @telemetry_handler_id,
      [:beamlens, :operator, :notification_sent],
      &__MODULE__.handle_telemetry_event/4,
      nil
    )

    {:ok, %{table: table}}
  end

  @impl true
  def terminate(_reason, _state) do
    :telemetry.detach(@telemetry_handler_id)
  end

  @doc false
  def handle_telemetry_event(_event, _measurements, %{notification: notification}, _config) do
    notification_data = %{
      id: notification.id,
      operator: notification.operator,
      anomaly_type: notification.anomaly_type,
      severity: notification.severity,
      summary: notification.summary,
      snapshots: notification.snapshots,
      detected_at: notification.detected_at,
      node: notification.node,
      trace_id: notification.trace_id,
      status: :unread
    }

    :ets.insert(@table_name, {notification.id, notification_data})
  end
end
