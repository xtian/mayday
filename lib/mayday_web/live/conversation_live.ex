defmodule MaydayWeb.ConversationLive do
  use MaydayWeb, :live_view

  import Ecto.Changeset, only: [get_field: 2]

  alias Mayday.{Campaigns, Contacts, Conversations}

  @impl true
  def mount(%{"campaign_id" => campaign_id, "id" => id}, _, %{assigns: assigns} = socket) do
    Conversations.read_conversation(id)

    campaign = Campaigns.get_campaign!(campaign_id)
    conversation = Conversations.get_conversation!(id, assigns.current_user.id)
    conversation_changeset = Conversations.change_conversation(conversation, %{})

    message_params =
      with true <- Enum.empty?(conversation.messages),
           [%{message_template: template} | _] <- campaign.script_messages do
        body = render_template(template, conversation.contact, assigns.current_user)
        %{body: body, conversation_id: conversation.id}
      else
        _ -> %{conversation_id: conversation.id}
      end

    if connected?(socket), do: Mayday.subscribe("conversations:#{conversation.id}")

    socket =
      socket
      |> assign(:campaign, campaign)
      |> assign(:conversation, conversation)
      |> assign(:conversation_changeset, conversation_changeset)
      |> assign(:message_changeset, Conversations.change_message(message_params))
      |> assign(:messages, conversation.messages)
      |> assign(:page_title, "Conversation with #{conversation.contact.first_name}")

    {:ok, socket, temporary_assigns: [messages: []]}
  end

  @impl true
  def handle_event("next-conversation", _, %{assigns: assigns} = socket) do
    socket =
      case Conversations.next_conversation(assigns.campaign.id, assigns.current_user.id) do
        {:ok, nil} ->
          path = Routes.conversations_path(socket, :index, assigns.campaign)

          socket
          |> push_redirect(to: path)
          |> put_flash(:info, "No new conversations available")

        {:ok, conversation} ->
          path = Routes.conversations_path(socket, :show, assigns.campaign, conversation)
          push_redirect(socket, to: path)
      end

    {:noreply, socket}
  end

  def handle_event("opt-out", _, %{assigns: assigns} = socket) do
    assigns.conversation.contact
    |> Contacts.opt_out_contact()
    |> case do
      :ok ->
        path = Routes.conversations_path(socket, :index, assigns.campaign)
        socket |> push_redirect(to: path) |> put_flash(:info, "Contact opted-out and deleted")

      _ ->
        put_flash(socket, :error, "Error opting-out contact")
    end
    |> then(&{:noreply, &1})
  end

  def handle_event("send-message", %{"message" => params}, %{assigns: assigns} = socket) do
    socket =
      case Conversations.send_message(
             params,
             campaign: assigns.campaign,
             conversation: assigns.conversation,
             current_user_id: assigns.current_user.id
           ) do
        {:ok, message} -> assign(socket, :messages, [message])
        {:error, changeset} -> assign(socket, :message_changeset, changeset)
      end

    {:noreply, socket}
  end

  def handle_event(
        "update-conversation",
        %{"conversation" => params},
        %{assigns: assigns} = socket
      ) do
    socket =
      case Conversations.update_conversation(assigns.conversation, params) do
        {:ok, conversation} -> assign(socket, :conversation, conversation)
        {:error, changeset} -> assign(socket, :conversation_changeset, changeset)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_message, message}, %{assigns: assigns} = socket) do
    Conversations.read_conversation(assigns.conversation.id)
    {:noreply, assign(socket, :messages, [message])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-screen-xl space-y-8 px-4 xl:px-0">
      <div x-data class="flex flex-col sm:flex-row h-[calc(100vh-3.25rem)]">
        <div class="flex grow flex-col py-4 sm:mr-6">
          <.back_link to={Routes.conversations_path(@socket, :index, @campaign)} />

          <h2 class="my-2 text-xl font-bold"><%= @page_title %></h2>

          <div
            class="flex grow flex-col space-y-4 overflow-y-auto"
            phx-update="append"
            id="messages"
            phx-hook="Messages"
            {tid(:messages)}
          >
            <%= for message <- @messages do %>
              <article
                id={"#{message.id}"}
                class={"#{if message.user_id, do: "self-end", else: "self-start"} flex flex-col space-y-1"}
              >
                <div class="flex items-end">
                  <div class={
                    "grow order-2 px-4 py-2 rounded-[1rem] #{if message.user_id, do: "bg-slate-300 text-white", else: "bg-gray-200"}"
                  }>
                    <%= format_body(message.body) %>
                  </div>

                  <%= if message.user_id do %>
                    <div class="order-3 ml-1 flex h-6 w-6 shrink-0 cursor-default select-none items-center justify-around rounded-full bg-slate-300 text-sm uppercase text-gray-400">
                      <div><%= String.first(@current_user.first_name) %></div>
                    </div>
                  <% else %>
                    <div class="order-1 mr-1 flex h-6 w-6 shrink-0 cursor-default select-none items-center justify-around rounded-full bg-gray-200 text-sm uppercase">
                      <div><%= String.first(@conversation.contact.first_name) %></div>
                    </div>
                  <% end %>
                </div>

                <time class="self-end text-xs text-gray-600">
                  <%= format_datetime(message.inserted_at) %>
                </time>
              </article>
            <% end %>
          </div>

          <.form :let={f} for={@message_changeset} phx-submit="send-message" class="mt-2" {tid(:message_form)}>
            <div class="flex items-center space-x-4">
              <%= textarea(f, :body, class: "Input grow", "x-ref": "body") %>
              <button class="Btn Btn--primary !rounded-full !p-3">
                <I.arrow_up class="h-5 w-5" />
              </button>
            </div>

            <%= error_tag(f, :body) %>
          </.form>
        </div>

        <div class="bg-gray-200/25 flex shrink-0 flex-col p-6 pb-8 sm:w-96">
          <.form
            :let={f}
            for={@conversation_changeset}
            phx-change="update-conversation"
            class="grow overflow-y-auto"
            {tid(:survey_form)}
          >
            <h3 class="mb-2 text-lg font-bold">Script</h3>
            <%= hidden_inputs_for(f) %>

            <%= for {ff, script_message} <- f |> inputs_for(:survey_responses) |> Enum.zip(@campaign.script_messages) do %>
              <%= hidden_input(ff, :id) %>
              <details {if get_field(ff.source, :value), do: [], else: [open: true]}>
                <summary class="mb-2 cursor-pointer border-b py-2">
                  <span class="text-red-500 underline">
                    <%= ff.index + 1 %>. <%= script_message.report_label %>
                  </span>
                </summary>

                <button
                  class="Btn Btn--secondary w-full"
                  type="button"
                  x-on:click="$refs.body.value = $el.title"
                  title={
                    render_template(
                      script_message.message_template,
                      @conversation.contact,
                      @current_user
                    )
                  }
                >
                  Paste Script Message
                </button>

                <div class="space-y-2 py-2">
                  <%= if Enum.empty?(script_message.survey_options) do %>
                    <label class="mt-2 block">
                      <%= checkbox(ff, :value, class: "Checkbox") %> Sent
                    </label>
                  <% else %>
                    <h4 class="my-2 font-bold">Survey</h4>

                    <%= for %{value: value} <- script_message.survey_options do %>
                      <label class="block">
                        <%= radio_button(ff, :value, value, class: "Checkbox !rounded-full") %>
                        <%= value %>
                      </label>
                    <% end %>
                  <% end %>

                  <%= error_tag(ff, :value) %>
                </div>
              </details>
            <% end %>
          </.form>

          <.form :let={f} for={@conversation_changeset} phx-change="update-conversation" class="py-4">
            <label>
              <div class="mb-2">Notes</div>
              <%= textarea(f, :notes, class: "Input", rows: 2) %>
            </label>
            <%= error_tag(f, :notes) %>
          </.form>

          <div class="flex space-x-4">
            <button class="Btn Btn--primary grow" phx-click="next-conversation" {tid(:next_conversation)}>
              New Conversation
            </button>

            <button
              class="Btn Btn--secondary"
              phx-click="opt-out"
              data-confirm="Opt this contact out of all future messages? This converation will be ended immediately."
              {tid(:opt_out)}
            >
              Opt Out
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp format_body(string) do
    string |> String.split("\n") |> Enum.intersperse(raw("<br/>"))
  end

  defp render_template(template, contact, user) do
    data = %{
      "contact" => %{"first_name" => contact.first_name, "last_name" => contact.last_name},
      "texter" => %{"first_name" => user.first_name, "last_name" => user.last_name}
    }

    case Campaigns.render_message_template(template, data) do
      {:ok, string} -> string
      {:error, _} -> ""
    end
  end
end
