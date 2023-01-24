defmodule Front.Router do
  use Front, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {Front.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Front do
    pipe_through :browser
    get "/", MedusaController, :index
    get "/medusa", MedusaController, :index
    get "/medusa/:server_id", MedusaController, :select
  end

  # Other scopes may use custom stacks.
  # scope "/api", Front do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access itkkkjkmmk
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also bbbbbbb,,,,,,,...mmmmnnnbbjkkkjkj/ial
  # uuuu
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: Front.Telemetry
    end
  end
end
