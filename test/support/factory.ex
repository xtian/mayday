defmodule Mayday.Factory do
  use ExMachina.Ecto, repo: Mayday.Repo

  alias Mayday.{Accounts, Campaigns, Contacts, Conversations}

  def user_factory do
    %Accounts.User{
      email: Faker.Internet.email(),
      first_name: Faker.Person.first_name(),
      hashed_password: Faker.String.base64(),
      last_name: Faker.Person.last_name(),
      role: :texter
    }
  end

  def campaign_factory do
    %Campaigns.Campaign{
      name: unique_string(),
      phone_number: fn -> insert(:provisioned_number).phone_number end,
      script_messages: [%Campaigns.ScriptMessage{message_template: unique_string()}]
    }
  end

  def contact_factory do
    %Contacts.Contact{
      first_name: Faker.Person.first_name(),
      phone_number: random_phone()
    }
  end

  def conversation_factory do
    %Conversations.Conversation{
      campaign: fn -> build(:campaign, started_at: Faker.DateTime.backward(1)) end,
      contact: fn -> build(:contact) end,
      survey_responses: [%{}],
      user: fn -> build(:user) end
    }
  end

  def provisioned_number_factory do
    %Campaigns.ProvisionedNumber{
      label: unique_string(),
      phone_number: random_phone()
    }
  end

  def random_phone do
    import Faker.Phone.EnUs

    Enum.join([area_code(), exchange_code(), subscriber_number()], "")
  end

  def unique_string do
    "#{System.unique_integer()}"
  end
end
