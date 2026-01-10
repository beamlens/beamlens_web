defmodule BeamlensWeb.AlertStore do
  @moduledoc """
  ETS-based store for alerts received from BeamLens watchers.

  Subscribes to `[:beamlens, :watcher, :alert_fired]` telemetry events
  and stores alerts for display in the dashboard.
  """

  use GenServer

  @table_name :beamlens_web_alerts
  @telemetry_handler_id "beamlens-web-alert-store"

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Returns all alerts, optionally filtered by status.
  """
  def list_alerts(status \\ nil) do
    case status do
      nil ->
        :ets.tab2list(@table_name)
        |> Enum.map(fn {_id, alert} -> alert end)
        |> Enum.sort_by(& &1.detected_at, {:desc, DateTime})

      status ->
        :ets.tab2list(@table_name)
        |> Enum.map(fn {_id, alert} -> alert end)
        |> Enum.filter(&(&1.status == status))
        |> Enum.sort_by(& &1.detected_at, {:desc, DateTime})
    end
  end

  @doc """
  Returns counts of alerts by status.
  """
  def counts do
    alerts = :ets.tab2list(@table_name) |> Enum.map(fn {_id, alert} -> alert end)

    %{
      total: length(alerts),
      unread: Enum.count(alerts, &(&1.status == :unread)),
      acknowledged: Enum.count(alerts, &(&1.status == :acknowledged)),
      resolved: Enum.count(alerts, &(&1.status == :resolved))
    }
  end

  @doc """
  Gets a single alert by ID.
  """
  def get_alert(id) do
    case :ets.lookup(@table_name, id) do
      [{^id, alert}] -> {:ok, alert}
      [] -> {:error, :not_found}
    end
  end

  @doc false
  # RPC callback for remote node queries
  def alerts_callback(status \\ nil) do
    list_alerts(status)
  end

  @doc false
  # RPC callback for remote node queries
  def alert_counts_callback do
    counts()
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:named_table, :set, :public, read_concurrency: true])

    :telemetry.attach(
      @telemetry_handler_id,
      [:beamlens, :watcher, :alert_fired],
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
  def handle_telemetry_event(_event, _measurements, %{alert: alert}, _config) do
    alert_data = %{
      id: alert.id,
      watcher: alert.watcher,
      anomaly_type: alert.anomaly_type,
      severity: alert.severity,
      summary: alert.summary,
      snapshots: alert.snapshots,
      detected_at: alert.detected_at,
      node: alert.node,
      trace_id: alert.trace_id,
      status: :unread
    }

    :ets.insert(@table_name, {alert.id, alert_data})
  end
end
