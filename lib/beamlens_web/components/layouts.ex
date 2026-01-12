defmodule BeamlensWeb.Layouts do
  @moduledoc """
  Layouts for the BeamLens dashboard.

  Uses Tailwind CSS with DaisyUI and a custom "Electric Blue" theme
  supporting light, dark, and system color scheme modes.
  """

  use BeamlensWeb, :html

  @doc """
  Root layout for the dashboard - includes HTML structure and external CSS.
  """
  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" data-theme="beamlens-dark" data-theme-mode="system">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Phoenix.Controller.get_csrf_token()} />
        <title>beamlens</title>
        <link rel="icon" type="image/x-icon" href="/favicon.ico" />
        <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32.png" />
        <link rel="icon" type="image/png" sizes="16x16" href="/favicon-16.png" />
        <link rel="apple-touch-icon" href="/images/logo/apple-touch-icon.png" />
        <link rel="stylesheet" href="/assets/app.css" />
        <script>
          // Apply theme before first paint to prevent flash
          (function() {
            const stored = localStorage.getItem('beamlens-theme');
            const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
            const theme = stored === 'light' ? 'beamlens-light' :
                          stored === 'dark' ? 'beamlens-dark' :
                          (prefersDark ? 'beamlens-dark' : 'beamlens-light');
            document.documentElement.setAttribute('data-theme', theme);
            document.documentElement.setAttribute('data-theme-mode', stored || 'system');
          })();
        </script>
        <script defer src="/assets/js/app.js"></script>
        <style>
          /* Copyable field styles */
          .copyable-field { cursor: text; }
          .copyable-field:hover .copy-icon { opacity: 0.5 !important; }
          .copyable-field:hover .copyable-text { text-decoration: underline; text-decoration-style: dotted; text-underline-offset: 2px; }
          /* Copy button styles */
          .copy-record-btn { cursor: pointer; }
          .copy-record-btn .hidden { display: none !important; }
          .copy-record-btn .check-icon { color: #22c55e; }
        </style>
        <script>
          // Theme switching functions
          window.setTheme = function(theme) {
            localStorage.setItem('beamlens-theme', theme);
            const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
            const effectiveTheme = theme === 'system'
              ? (prefersDark ? 'beamlens-dark' : 'beamlens-light')
              : (theme === 'dark' ? 'beamlens-dark' : 'beamlens-light');
            document.documentElement.setAttribute('data-theme', effectiveTheme);
            document.documentElement.setAttribute('data-theme-mode', theme);
          };

          // Listen for system theme changes
          window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
            const stored = localStorage.getItem('beamlens-theme');
            if (!stored || stored === 'system') {
              document.documentElement.setAttribute('data-theme',
                e.matches ? 'beamlens-dark' : 'beamlens-light');
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

          // Copy to clipboard function - called directly from onclick
          window.copyToClipboard = function(el, copyId) {
            const text = el.getAttribute('data-copy-text');
            navigator.clipboard.writeText(text).then(() => {
              showCopiedTooltip(el);
            });
          };

          // Copy record (JSON) to clipboard - shows checkmark instead of tooltip
          window.copyRecordToClipboard = function(el) {
            const json = el.getAttribute('data-copy-json');
            try {
              const formatted = JSON.stringify(JSON.parse(json), null, 2);
              navigator.clipboard.writeText(formatted).then(() => {
                showCopyCheckmark(el);
              });
            } catch (e) {
              navigator.clipboard.writeText(json).then(() => {
                showCopyCheckmark(el);
              });
            }
          };

          // Show checkmark icon temporarily for copy button
          window.showCopyCheckmark = function(btn) {
            const copyIcon = btn.querySelector('.copy-icon');
            const checkIcon = btn.querySelector('.check-icon');
            if (copyIcon && checkIcon) {
              copyIcon.classList.add('hidden');
              checkIcon.classList.remove('hidden');
              setTimeout(() => {
                checkIcon.classList.add('hidden');
                copyIcon.classList.remove('hidden');
              }, 1500);
            }
          };

          // Show "Copied!" tooltip near an element
          window.showCopiedTooltip = function(el) {
            const container = document.getElementById('tooltip-container') || document.body;
            const tooltip = document.createElement("div");
            tooltip.textContent = "Copied!";
            tooltip.style.cssText = "position:fixed;z-index:99999;padding:4px 8px;font-size:12px;font-weight:500;color:#fff;background:#22c55e;border-radius:4px;box-shadow:0 4px 6px -1px rgba(0,0,0,0.1);pointer-events:none;";
            container.appendChild(tooltip);

            // Position tooltip above element
            const rect = el.getBoundingClientRect();
            const tooltipRect = tooltip.getBoundingClientRect();

            let left = rect.left + (rect.width / 2) - (tooltipRect.width / 2);
            let top = rect.top - tooltipRect.height - 6;

            // Keep within viewport bounds
            if (left < 8) left = 8;
            if (left + tooltipRect.width > window.innerWidth - 8) {
              left = window.innerWidth - tooltipRect.width - 8;
            }
            if (top < 8) {
              top = rect.bottom + 6; // Show below if no room above
            }

            tooltip.style.left = `${left}px`;
            tooltip.style.top = `${top}px`;

            // Fade out and remove
            setTimeout(() => {
              tooltip.style.transition = "opacity 0.2s";
              tooltip.style.opacity = "0";
              setTimeout(() => tooltip.remove(), 200);
            }, 1200);
          };
        </script>
      </head>
      <body class="min-h-screen bg-base-100 text-base-content">
        <%= @inner_content %>
        <div id="tooltip-container" phx-update="ignore"></div>
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
