defmodule BeamlensWeb.Layouts do
  @moduledoc """
  Layouts for the BeamLens dashboard.

  Uses Tailwind CSS with DaisyUI and a custom "Warm Ember" theme
  supporting light, dark, and system color scheme modes.
  """

  use BeamlensWeb, :html

  @doc """
  Root layout for the dashboard - includes HTML structure and external CSS.
  """
  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" data-theme="warm-ember-dark" data-theme-mode="system">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Phoenix.Controller.get_csrf_token()} />
        <title>BeamLens Dashboard</title>
        <link rel="stylesheet" href="/assets/app.css" />
        <script>
          // Apply theme before first paint to prevent flash
          (function() {
            const stored = localStorage.getItem('beamlens-theme');
            const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
            const theme = stored === 'light' ? 'warm-ember-light' :
                          stored === 'dark' ? 'warm-ember-dark' :
                          (prefersDark ? 'warm-ember-dark' : 'warm-ember-light');
            document.documentElement.setAttribute('data-theme', theme);
            document.documentElement.setAttribute('data-theme-mode', stored || 'system');
          })();
        </script>
        <script defer src="/assets/js/app.js"></script>
        <script>
          // Theme switching functions
          window.setTheme = function(theme) {
            localStorage.setItem('beamlens-theme', theme);
            const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
            const effectiveTheme = theme === 'system'
              ? (prefersDark ? 'warm-ember-dark' : 'warm-ember-light')
              : (theme === 'dark' ? 'warm-ember-dark' : 'warm-ember-light');
            document.documentElement.setAttribute('data-theme', effectiveTheme);
            document.documentElement.setAttribute('data-theme-mode', theme);
          };

          // Listen for system theme changes
          window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
            const stored = localStorage.getItem('beamlens-theme');
            if (!stored || stored === 'system') {
              document.documentElement.setAttribute('data-theme',
                e.matches ? 'warm-ember-dark' : 'warm-ember-light');
            }
          });

          // Download handler for export feature
          window.addEventListener("phx:download", (e) => {
            const {content, filename} = e.detail;
            const blob = new Blob([content], {type: "application/json"});
            const url = URL.createObjectURL(blob);
            const a = document.createElement("a");
            a.href = url;
            a.download = filename;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
          });
        </script>
      </head>
      <body class="min-h-screen bg-base-100 text-base-content">
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
end
