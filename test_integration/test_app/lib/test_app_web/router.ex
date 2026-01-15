defmodule TestAppWeb.Router do
  use Phoenix.Router
  import BeamlensWeb.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
  end

  scope "/" do
    pipe_through :browser
    beamlens_web "/dashboard"
  end
end
