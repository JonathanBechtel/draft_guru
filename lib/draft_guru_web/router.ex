defmodule DraftGuruWeb.Router do
  use DraftGuruWeb, :router

  import DraftGuruWeb.UsersAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DraftGuruWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_users
  end

  pipeline :api do
    plug :accepts, ["json"]
end

  pipeline :basic_auth do
    plug DraftGuruWeb.Plugs.BasicAuth
  end

  pipeline :require_admin do
    plug DraftGuruWeb.Plugs.RequireAdmin
  end

  scope "/", DraftGuruWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/", DraftGuruWeb do
    pipe_through [:browser, :require_authenticated_users, :require_admin]

    resources "/models/player_canonical", PlayerController
    resources "/player_id_lookup", PlayerIdLookupController, only: [:show, :index]
    resources "/player_combine_stats", PlayerCombineStatsController
  end

  # Other scopes may use custom stacks.
  # scope "/api", DraftGuruWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:draft_guru, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DraftGuruWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", DraftGuruWeb do
    pipe_through [:browser, :redirect_if_users_is_authenticated, :basic_auth]

    get "/users/register", UsersRegistrationController, :new
    post "/users/register", UsersRegistrationController, :create
    get "/users/log_in", UsersSessionController, :new
    post "/users/log_in", UsersSessionController, :create
    get "/users/reset_password", UsersResetPasswordController, :new
    post "/users/reset_password", UsersResetPasswordController, :create
    get "/users/reset_password/:token", UsersResetPasswordController, :edit
    put "/users/reset_password/:token", UsersResetPasswordController, :update
  end

  scope "/", DraftGuruWeb do
    pipe_through [:browser, :require_authenticated_users]

    get "/users/settings", UsersSettingsController, :edit
    put "/users/settings", UsersSettingsController, :update
    get "/users/settings/confirm_email/:token", UsersSettingsController, :confirm_email
  end

  scope "/", DraftGuruWeb do
    pipe_through [:browser, :basic_auth]

    delete "/users/log_out", UsersSessionController, :delete
    get "/users/confirm", UsersConfirmationController, :new
    post "/users/confirm", UsersConfirmationController, :create
    get "/users/confirm/:token", UsersConfirmationController, :edit
    post "/users/confirm/:token", UsersConfirmationController, :update
  end
end
