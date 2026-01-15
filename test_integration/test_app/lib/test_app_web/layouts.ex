defmodule TestAppWeb.Layouts do
  use Phoenix.Component

  def render("root.html", assigns) do
    ~H"""
    <html>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <.live_title suffix=" - Test App">
          <%= assigns[:page_title] || "Test App" %>
        </.live_title>
        <link phx-track-static rel="stylesheet" href="/assets/app.css" />
      </head>
      <body>
        <%= @inner_content %>
      </body>
    </html>
    """
  end
end
