defmodule Mayday.Actions.ActionNotifier do
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

  def deliver_action_confirmation(action) do
    deliver(action.submitter_email, "Your action was submitted successfully", """
    Hi #{action.submitter_name},

    Thank you for submitting your action! We will notify the club as soon as possible.

    ==============================

    Action Details:

    #{action.title}
    #{Calendar.strftime(action.starts_at, "%A, %B %d")}
    #{Calendar.strftime(action.starts_at, "%I:%M %p")}#{if action.ends_at, do: "–" <> Calendar.strftime(action.ends_at, "%I:%M %p")}

    Sponsor: #{action.sponsor}
    Cost to Attend: #{action.cost_to_attend}
    URL: #{action.url}
    Address:
    #{action.address}

    Description:
    #{action.description}

    """)
  end
end
