defmodule Mayday.Accounts.UserNotifier do
  import Swoosh.Email

  alias Mayday.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email_host = Application.fetch_env!(:mayday, :email_host)

    email =
      new()
      |> to(recipient)
      |> from({"Mayday", "noreply@#{email_host}"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  def deliver_invitation_instructions(user, url) do
    deliver(user.email, "You‘ve been invited to join the Mayday app", """

    ==============================

    Hi #{user.first_name},

    You have been invited to send text messages.

    You can set up your account by visiting the URL below:

    #{url}

    ==============================
    """)
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Reset password instructions", """

    ==============================

    Hi #{user.first_name},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.first_name},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
