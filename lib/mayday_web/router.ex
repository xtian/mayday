defmodule MaydayWeb.Router do
  use MaydayWeb, :router

  import MaydayWeb.UserAuth

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {MaydayWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  scope "/turnout/admin", MaydayWeb do
    pipe_through :browser

    live_session :owner, on_mount: {MaydayWeb.UserLiveAuth, :owner} do
      live "/actions", ActionsLive, :index
    end

    live_session :admin, on_mount: {MaydayWeb.UserLiveAuth, :admin} do
      live "/contacts", ContactsLive, :index
      live "/contacts/new", ContactFormLive, :new, as: :contacts
      live "/contacts/:id/edit", ContactFormLive, :edit, as: :contacts

      live "/provisioned_numbers", ProvisionedNumbersLive, :index
      live "/provisioned_numbers/new", ProvisionedNumberFormLive, :new, as: :provisioned_numbers

      live "/provisioned_numbers/:id/edit", ProvisionedNumberFormLive, :edit,
        as: :provisioned_numbers

      live "/users", UsersLive, :index
      live "/users/new", UserFormLive, :new, as: :users
      live "/users/:id/edit", UserFormLive, :edit, as: :users
    end

    live_session :manager, on_mount: {MaydayWeb.UserLiveAuth, :manager} do
      live "/campaigns", CampaignsLive, :index
      live "/campaigns/new", CampaignFormLive, :new, as: :campaigns
      live "/campaigns/:id", CampaignLive, :show, as: :campaigns
      live "/campaigns/:id/edit", CampaignFormLive, :edit, as: :campaigns
    end
  end

  scope "/turnout", MaydayWeb do
    pipe_through :browser

    live_session :texter, on_mount: {MaydayWeb.UserLiveAuth, :texter} do
      live "/", DashboardLive, :index
      live "/campaigns/:campaign_id/conversations", ConversationsLive, :index

      live "/campaigns/:campaign_id/conversations/:id", ConversationLive, :show,
        as: :conversations
    end
  end

  scope "/turnout", MaydayWeb do
    pipe_through [:browser, :require_admin_user]

    get "/contacts.csv", FileController, :download_contacts
    get "/campaigns/:id/responses.csv", FileController, :download_responses
  end

  scope "/", MaydayWeb do
    pipe_through :browser

    live "/new_action", ActionFormLive, :new, as: :actions
  end

  ## API routes

  get "/ping.txt", MaydayWeb.PingController, :index

  scope "/api", MaydayWeb do
    pipe_through [:api]

    post "/messages", WebhookController, :create
  end

  ## Authentication routes

  scope "/", MaydayWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", MaydayWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/", RedirectController, :show
    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", MaydayWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/accept_invite/:token", UserInvitationController, :edit
    put "/users/accept_invite/:token", UserInvitationController, :update
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MaydayWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
