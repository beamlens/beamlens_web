defmodule TestAppWeb do
  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: TestAppWeb.Layouts]
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/test_app_web",
        namespace: TestAppWeb
    end
  end

  def router do
    quote do
      use Phoenix.Router
    end
  end

  def component do
    quote do
      use Phoenix.Component
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
