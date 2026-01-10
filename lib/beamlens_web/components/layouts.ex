defmodule BeamlensWeb.Layouts do
  @moduledoc """
  Layouts for the BeamLens dashboard.
  """

  use BeamlensWeb, :html

  @doc """
  Root layout for the dashboard - includes HTML structure and CSS.
  """
  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" data-theme="beamlens-dark">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Phoenix.Controller.get_csrf_token()} />
        <title>BeamLens Dashboard</title>
        <style>
          <%= raw(BeamlensWeb.Layouts.css()) %>
        </style>
        <script defer src="/assets/js/app.js"></script>
      </head>
      <body class="beamlens-dashboard">
        <%= @inner_content %>
      </body>
    </html>
    """
  end

  @doc """
  Dashboard layout wrapper.
  """
  def dashboard(assigns) do
    ~H"""
    <%= @inner_content %>
    """
  end

  @doc """
  Returns the dashboard CSS styles (Warm Ember theme).
  """
  def css do
    """
    :root {
      --brand-orange: #FD4F00;
      --accent-teal: #14B8A6;
      --surface: #0f1115;
      --surface-alt: #1a1d23;
      --surface-elevated: #252930;
      --border: #2d3139;
      --text-primary: #f3f4f6;
      --text-secondary: #9ca3af;
      --text-muted: #6b7280;

      --success: #10b981;
      --warning: #f59e0b;
      --error: #ef4444;
      --info: #06b6d4;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      background-color: var(--surface);
      color: var(--text-primary);
      line-height: 1.5;
    }

    .beamlens-dashboard {
      min-height: 100vh;
      display: flex;
      flex-direction: column;
    }

    /* Dashboard Layout - Sidebar + Main */
    .dashboard-layout {
      display: grid;
      grid-template-columns: 220px 1fr;
      grid-template-rows: auto 1fr;
      height: 100vh;
      overflow: hidden;
    }

    .dashboard-layout .dashboard-header {
      grid-column: 1 / -1;
    }

    /* Sidebar */
    .dashboard-sidebar {
      background: var(--surface-alt);
      border-right: 1px solid var(--border);
      overflow-y: auto;
      padding: 0.75rem 0;
    }

    .sidebar-section {
      padding: 0 0.5rem;
      margin-bottom: 1rem;
    }

    .sidebar-section-title {
      font-size: 0.6875rem;
      font-weight: 600;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.05em;
      padding: 0.5rem 0.75rem;
      margin-bottom: 0.25rem;
    }

    .sidebar-item {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      width: 100%;
      padding: 0.5rem 0.75rem;
      background: transparent;
      border: none;
      border-radius: 0.375rem;
      color: var(--text-secondary);
      font-size: 0.8125rem;
      cursor: pointer;
      transition: all 0.15s ease;
      text-align: left;
    }

    .sidebar-item:hover {
      background: var(--surface-elevated);
      color: var(--text-primary);
    }

    .sidebar-item.selected {
      background: rgba(253, 79, 0, 0.1);
      color: var(--brand-orange);
    }

    .sidebar-item-icon {
      font-size: 0.875rem;
      width: 1.25rem;
      text-align: center;
      flex-shrink: 0;
    }

    .sidebar-item-label {
      flex: 1;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .sidebar-item-count {
      background: var(--surface-elevated);
      padding: 0.125rem 0.5rem;
      border-radius: 9999px;
      font-size: 0.6875rem;
      font-weight: 600;
      color: var(--text-muted);
    }

    .sidebar-item.selected .sidebar-item-count {
      background: rgba(253, 79, 0, 0.2);
      color: var(--brand-orange);
    }

    .sidebar-item-meta {
      font-size: 0.6875rem;
      color: var(--text-muted);
    }

    .sidebar-status-dot {
      width: 0.5rem;
      height: 0.5rem;
      border-radius: 50%;
      flex-shrink: 0;
    }

    .sidebar-status-dot.status-healthy { background: var(--success); }
    .sidebar-status-dot.status-observing { background: var(--info); }
    .sidebar-status-dot.status-warning { background: var(--warning); }
    .sidebar-status-dot.status-critical { background: var(--error); }
    .sidebar-status-dot.status-running { background: var(--success); }
    .sidebar-status-dot.status-stopped { background: var(--error); }

    .sidebar-state-badge {
      font-size: 0.625rem;
      padding: 0.125rem 0.375rem;
      border-radius: 0.25rem;
      text-transform: uppercase;
      font-weight: 600;
    }

    .coordinator-stats {
      display: flex;
      gap: 1rem;
      padding: 0.25rem 0.75rem 0.5rem 2rem;
    }

    .coordinator-stat {
      display: flex;
      align-items: baseline;
      gap: 0.25rem;
    }

    .coordinator-stat .stat-count {
      font-size: 0.875rem;
      font-weight: 600;
      color: var(--text-primary);
    }

    .coordinator-stat .stat-label {
      font-size: 0.6875rem;
      color: var(--text-muted);
    }

    .sidebar-empty {
      padding: 0.5rem 0.75rem;
      font-size: 0.75rem;
      color: var(--text-muted);
      font-style: italic;
    }

    /* Main Panel */
    .dashboard-main {
      overflow-y: auto;
      padding: 1rem 1.5rem;
      background: var(--surface);
    }

    .main-panel {
      display: flex;
      flex-direction: column;
      gap: 1rem;
      height: 100%;
    }

    .panel-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 1rem;
      flex-shrink: 0;
    }

    .panel-title {
      font-size: 1rem;
      font-weight: 600;
      color: var(--text-primary);
    }

    .panel-controls {
      display: flex;
      align-items: center;
      gap: 1rem;
    }

    .type-filter-form {
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }

    .type-filter-form label {
      font-size: 0.8125rem;
      color: var(--text-muted);
    }

    .type-filter-form select {
      background: var(--surface-elevated);
      border: 1px solid var(--border);
      border-radius: 0.375rem;
      color: var(--text-primary);
      font-size: 0.8125rem;
      padding: 0.375rem 0.625rem;
      cursor: pointer;
    }

    .type-filter-form select:hover {
      border-color: var(--text-muted);
    }

    .type-filter-form select:focus {
      outline: none;
      border-color: var(--brand-orange);
    }

    .panel-summary {
      flex-shrink: 0;
      max-height: 300px;
      overflow-y: auto;
    }

    .panel-summary.empty {
      max-height: none;
    }

    /* Header */
    .dashboard-header {
      background: var(--surface-alt);
      border-bottom: 1px solid var(--border);
      padding: 1rem 1.5rem;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }

    .dashboard-header h1 {
      font-size: 1.25rem;
      font-weight: 600;
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }

    .dashboard-header h1 .logo {
      color: var(--brand-orange);
    }

    .header-status {
      display: flex;
      align-items: center;
      gap: 1rem;
      font-size: 0.875rem;
      color: var(--text-secondary);
    }

    /* Tabs */
    .tab-nav {
      display: flex;
      gap: 0.25rem;
      padding: 0 1.5rem;
      background: var(--surface-alt);
      border-bottom: 1px solid var(--border);
    }

    .tab-btn {
      padding: 0.75rem 1.25rem;
      background: transparent;
      border: none;
      color: var(--text-secondary);
      font-size: 0.875rem;
      font-weight: 500;
      cursor: pointer;
      border-bottom: 2px solid transparent;
      transition: all 0.15s ease;
    }

    .tab-btn:hover {
      color: var(--text-primary);
      background: var(--surface-elevated);
    }

    .tab-btn.active {
      color: var(--brand-orange);
      border-bottom-color: var(--brand-orange);
    }

    /* Content */
    .dashboard-content {
      flex: 1;
      padding: 1.5rem;
      overflow-y: auto;
    }

    /* Cards */
    .card {
      background: var(--surface-alt);
      border: 1px solid var(--border);
      border-radius: 0.5rem;
      margin-bottom: 1rem;
      overflow: hidden;
    }

    .card-header {
      padding: 1rem;
      display: flex;
      align-items: center;
      gap: 0.75rem;
      border-bottom: 1px solid var(--border);
    }

    .card-body {
      padding: 1rem;
    }

    /* Badges */
    .badge {
      display: inline-flex;
      align-items: center;
      padding: 0.25rem 0.625rem;
      font-size: 0.75rem;
      font-weight: 600;
      border-radius: 9999px;
      text-transform: uppercase;
      letter-spacing: 0.025em;
    }

    .badge-healthy { background: rgba(16, 185, 129, 0.15); color: #34d399; }
    .badge-observing { background: rgba(59, 130, 246, 0.15); color: #60a5fa; }
    .badge-warning { background: rgba(245, 158, 11, 0.15); color: #fbbf24; }
    .badge-critical { background: rgba(239, 68, 68, 0.15); color: #f87171; }

    .badge-info { background: rgba(6, 182, 212, 0.15); color: #22d3ee; }

    .badge-temporal { background: rgba(168, 85, 247, 0.15); color: #c084fc; }
    .badge-causal { background: rgba(59, 130, 246, 0.15); color: #60a5fa; }
    .badge-symptomatic { background: rgba(20, 184, 166, 0.15); color: #2dd4bf; }

    .badge-high { background: rgba(16, 185, 129, 0.15); color: #34d399; }
    .badge-medium { background: rgba(245, 158, 11, 0.15); color: #fbbf24; }
    .badge-low { background: rgba(239, 68, 68, 0.15); color: #f87171; }

    .badge-unread { background: rgba(253, 79, 0, 0.15); color: var(--brand-orange); }
    .badge-acknowledged { background: rgba(245, 158, 11, 0.15); color: #fbbf24; }
    .badge-resolved { background: rgba(16, 185, 129, 0.15); color: #34d399; }

    /* Status indicator */
    .status-dot {
      width: 0.5rem;
      height: 0.5rem;
      border-radius: 50%;
      display: inline-block;
    }

    .status-dot.running { background: var(--success); }
    .status-dot.stopped { background: var(--error); }

    /* Watcher card */
    .watcher-name {
      font-weight: 600;
      font-size: 0.9375rem;
    }

    .watcher-running {
      margin-left: auto;
      display: flex;
      align-items: center;
      gap: 0.375rem;
      font-size: 0.8125rem;
      color: var(--text-secondary);
    }

    /* Alert card */
    .alert-summary {
      font-size: 0.9375rem;
      margin-bottom: 0.5rem;
    }

    .alert-meta {
      display: flex;
      flex-wrap: wrap;
      gap: 0.75rem;
      font-size: 0.8125rem;
      color: var(--text-secondary);
    }

    /* Insight card */
    .insight-summary {
      font-size: 0.9375rem;
      margin-bottom: 0.75rem;
    }

    .insight-hypothesis {
      background: var(--surface);
      padding: 0.75rem;
      border-radius: 0.375rem;
      font-size: 0.875rem;
      color: var(--text-secondary);
      margin-bottom: 0.75rem;
    }

    .insight-meta {
      display: flex;
      flex-wrap: wrap;
      gap: 0.75rem;
      font-size: 0.8125rem;
      color: var(--text-secondary);
    }

    /* Coordinator status */
    .coordinator-status {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
      gap: 1rem;
      margin-bottom: 1.5rem;
    }

    .stat-card {
      background: var(--surface-alt);
      border: 1px solid var(--border);
      border-radius: 0.5rem;
      padding: 1rem;
    }

    .stat-label {
      font-size: 0.75rem;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.05em;
      margin-bottom: 0.25rem;
    }

    .stat-value {
      font-size: 1.5rem;
      font-weight: 600;
    }

    /* Empty state */
    .empty-state {
      text-align: center;
      padding: 3rem 1rem;
      color: var(--text-muted);
    }

    .empty-state-icon {
      font-size: 2.5rem;
      margin-bottom: 0.75rem;
      opacity: 0.5;
    }

    /* Grid for watchers */
    .watcher-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
      gap: 1rem;
    }

    /* Section headers */
    .section-header {
      font-size: 0.875rem;
      font-weight: 600;
      color: var(--text-secondary);
      text-transform: uppercase;
      letter-spacing: 0.05em;
      margin-bottom: 1rem;
    }

    /* Timestamp */
    .timestamp {
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
      font-size: 0.75rem;
    }

    /* Filter pills */
    .filter-pills {
      display: flex;
      gap: 0.5rem;
      margin-bottom: 1rem;
    }

    .filter-pill {
      padding: 0.375rem 0.875rem;
      background: var(--surface-alt);
      border: 1px solid var(--border);
      border-radius: 9999px;
      font-size: 0.8125rem;
      color: var(--text-secondary);
      cursor: pointer;
      transition: all 0.15s ease;
    }

    .filter-pill:hover {
      border-color: var(--text-muted);
    }

    .filter-pill.active {
      background: rgba(253, 79, 0, 0.15);
      border-color: var(--brand-orange);
      color: var(--brand-orange);
    }

    /* Node selector */
    .node-selector {
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }

    .node-selector label {
      font-size: 0.8125rem;
      color: var(--text-muted);
    }

    .node-selector select {
      background: var(--surface-elevated);
      border: 1px solid var(--border);
      border-radius: 0.375rem;
      color: var(--text-primary);
      font-size: 0.8125rem;
      padding: 0.375rem 0.625rem;
      cursor: pointer;
    }

    .node-selector select:hover {
      border-color: var(--text-muted);
    }

    .node-selector select:focus {
      outline: none;
      border-color: var(--brand-orange);
    }

    /* Node badge */
    .node-badge {
      display: inline-flex;
      align-items: center;
      padding: 0.125rem 0.5rem;
      font-size: 0.6875rem;
      font-weight: 500;
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 0.25rem;
      color: var(--text-muted);
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
    }

    /* Event Log */
    .event-log {
      background: var(--surface-alt);
      border: 1px solid var(--border);
      border-radius: 0.5rem;
      max-height: 600px;
      overflow-y: auto;
    }

    .event-list {
      display: flex;
      flex-direction: column;
    }

    .event-row {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      padding: 0.625rem 1rem;
      border-bottom: 1px solid var(--border);
      font-size: 0.8125rem;
    }

    .event-row:last-child {
      border-bottom: none;
    }

    .event-row:hover {
      background: var(--surface-elevated);
    }

    .event-timestamp {
      color: var(--text-muted);
      flex-shrink: 0;
    }

    .event-type-badge {
      padding: 0.125rem 0.5rem;
      font-size: 0.6875rem;
      font-weight: 600;
      border-radius: 0.25rem;
      text-transform: uppercase;
      letter-spacing: 0.025em;
      flex-shrink: 0;
      min-width: 5rem;
      text-align: center;
    }

    /* Event type badge colors */
    .badge-iteration { background: rgba(59, 130, 246, 0.15); color: #60a5fa; }
    .badge-state { background: rgba(168, 85, 247, 0.15); color: #c084fc; }
    .badge-alert { background: rgba(239, 68, 68, 0.15); color: #f87171; }
    .badge-snapshot { background: rgba(20, 184, 166, 0.15); color: #2dd4bf; }
    .badge-wait { background: rgba(107, 114, 128, 0.15); color: #9ca3af; }
    .badge-think { background: rgba(245, 158, 11, 0.15); color: #fbbf24; }
    .badge-error { background: rgba(239, 68, 68, 0.2); color: #f87171; }
    .badge-received { background: rgba(253, 79, 0, 0.15); color: var(--brand-orange); }
    .badge-insight { background: rgba(16, 185, 129, 0.15); color: #34d399; }
    .badge-done { background: rgba(16, 185, 129, 0.15); color: #34d399; }
    .badge-default { background: rgba(107, 114, 128, 0.15); color: #9ca3af; }

    .event-source {
      color: var(--text-secondary);
      font-weight: 500;
      flex-shrink: 0;
      min-width: 6rem;
    }

    .event-details {
      color: var(--text-primary);
      flex: 1;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .event-trace-id {
      color: var(--text-muted);
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
      font-size: 0.6875rem;
      flex-shrink: 0;
    }

    /* Event filters */
    .event-filters {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 1rem;
      margin-bottom: 1rem;
    }

    .filter-form {
      display: flex;
      align-items: center;
      gap: 1rem;
      flex-wrap: wrap;
    }

    .filter-group {
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }

    .filter-group label {
      font-size: 0.8125rem;
      color: var(--text-muted);
    }

    .filter-group select {
      background: var(--surface-elevated);
      border: 1px solid var(--border);
      border-radius: 0.375rem;
      color: var(--text-primary);
      font-size: 0.8125rem;
      padding: 0.375rem 0.625rem;
      cursor: pointer;
    }

    .filter-group select:hover {
      border-color: var(--text-muted);
    }

    .filter-group select:focus {
      outline: none;
      border-color: var(--brand-orange);
    }

    .filter-clear-btn {
      background: transparent;
      border: 1px solid var(--border);
      border-radius: 0.375rem;
      color: var(--text-secondary);
      font-size: 0.8125rem;
      padding: 0.375rem 0.75rem;
      cursor: pointer;
      transition: all 0.15s ease;
    }

    .filter-clear-btn:hover {
      border-color: var(--text-muted);
      color: var(--text-primary);
    }

    /* Pause button */
    .pause-btn {
      display: flex;
      align-items: center;
      gap: 0.375rem;
      background: var(--surface-elevated);
      border: 1px solid var(--border);
      border-radius: 0.375rem;
      color: var(--text-secondary);
      font-size: 0.8125rem;
      padding: 0.375rem 0.75rem;
      cursor: pointer;
      transition: all 0.15s ease;
      flex-shrink: 0;
    }

    .pause-btn:hover {
      border-color: var(--text-muted);
      color: var(--text-primary);
    }

    .pause-btn.paused {
      background: rgba(253, 79, 0, 0.15);
      border-color: var(--brand-orange);
      color: var(--brand-orange);
    }

    .pause-btn.paused:hover {
      background: rgba(253, 79, 0, 0.25);
    }

    .pause-icon {
      font-size: 0.75rem;
    }

    /* Expandable event rows */
    .event-row-container {
      border-bottom: 1px solid var(--border);
    }

    .event-row-container:last-child {
      border-bottom: none;
    }

    .event-row-container.expanded {
      background: var(--surface);
    }

    .event-row {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      padding: 0.625rem 1rem;
      font-size: 0.8125rem;
      cursor: pointer;
      transition: background 0.15s ease;
    }

    .event-row:hover {
      background: var(--surface-elevated);
    }

    .event-row.selected {
      background: var(--surface-elevated);
    }

    .event-expand-icon {
      color: var(--text-muted);
      font-size: 0.625rem;
      width: 0.75rem;
      flex-shrink: 0;
    }

    /* Event detail view */
    .event-detail {
      padding: 1rem 1rem 1rem 2.5rem;
      background: var(--surface);
      border-top: 1px solid var(--border);
    }

    .event-detail-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 1.5rem;
    }

    @media (max-width: 768px) {
      .event-detail-grid {
        grid-template-columns: 1fr;
      }
    }

    .event-detail-section h4 {
      font-size: 0.75rem;
      font-weight: 600;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.05em;
      margin-bottom: 0.75rem;
      padding-bottom: 0.5rem;
      border-bottom: 1px solid var(--border);
    }

    .event-detail-section dl {
      display: grid;
      grid-template-columns: auto 1fr;
      gap: 0.375rem 1rem;
      font-size: 0.8125rem;
    }

    .event-detail-section dt {
      color: var(--text-muted);
      font-weight: 500;
    }

    .event-detail-section dd {
      color: var(--text-primary);
      word-break: break-word;
    }

    .event-detail-section code {
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
      font-size: 0.75rem;
      background: var(--surface-alt);
      padding: 0.125rem 0.375rem;
      border-radius: 0.25rem;
      color: var(--accent-teal);
    }

    .event-detail-section .text-muted {
      color: var(--text-muted);
      font-style: italic;
    }
    """
  end
end
