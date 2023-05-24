defmodule MaydayWeb.CampaignFormLive do
  use MaydayWeb, :live_view

  import Ecto.Changeset, only: [get_field: 2]

  alias Mayday.{Campaigns, Contacts}

  @impl true
  def mount(params, _, socket) do
    assigns =
      case params do
        %{"id" => id} ->
          campaign = Campaigns.get_campaign!(id)

          [
            campaign: campaign,
            changeset: Campaigns.change_campaign(campaign, %{}),
            page_title: "Update Campaign"
          ]

        _ ->
          [
            campaign: nil,
            changeset: %{} |> Campaigns.change_campaign() |> Campaigns.add_script_message(),
            page_title: "Create New Campaign"
          ]
      end

    provisioned_numbers = Enum.map(Campaigns.provisioned_numbers(), &{&1.label, &1.phone_number})

    {:ok, socket |> assign(:provisioned_numbers, provisioned_numbers) |> assign(assigns)}
  end

  @impl true
  def handle_event("add-script-message", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, :changeset, Campaigns.add_script_message(assigns.changeset))}
  end

  def handle_event("add-survey-response", %{"index" => index}, %{assigns: assigns} = socket) do
    changeset = Campaigns.add_survey_option(assigns.changeset, String.to_integer(index))
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    socket =
      case id |> String.to_integer() |> Campaigns.delete_campaign() do
        :ok ->
          socket
          |> put_flash(:info, "Campaign deleted")
          |> push_redirect(to: Routes.campaigns_path(socket, :index))

        _ ->
          socket
      end

    {:noreply, socket}
  end

  def handle_event("remove-script-message", %{"index" => index}, %{assigns: assigns} = socket) do
    changeset = Campaigns.remove_script_message(assigns.changeset, String.to_integer(index))
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("remove-survey-response", params, %{assigns: assigns} = socket) do
    [script_index, survey_index] =
      params
      |> Map.take(["script-index", "survey-index"])
      |> Map.values()
      |> Enum.map(&String.to_integer/1)

    changeset = Campaigns.remove_survey_option(assigns.changeset, script_index, survey_index)
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"campaign" => params}, %{assigns: assigns} = socket) do
    case Campaigns.save_campaign(assigns.campaign, params) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "Campaign saved")
          |> push_redirect(to: Routes.campaigns_path(socket, :index))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("validate", %{"campaign" => params}, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, :changeset, Campaigns.change_campaign(assigns.campaign, params))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.wrapper>
      <.back_link to={Routes.campaigns_path(@socket, :index)} />

      <div class="flex max-w-lg justify-between">
        <h2 class="text-3xl font-bold"><%= @page_title %></h2>

        <%= if @campaign do %>
          <button
            type="button"
            class="flex items-center space-x-2 text-red-500"
            data-confirm="Are you sure you want to delete this campaign? This cannot be undone."
            phx-click="delete"
            phx-value-id={@campaign.id}
            {tid(:delete_campaign)}
          >
            <I.trash class="h-5 w-5" />
            <span>Delete</span>
          </button>
        <% end %>
      </div>

      <.form
        :let={f}
        for={@changeset}
        phx-change="validate"
        phx-submit="save"
        phx-throttle="50"
        class="flex flex-col"
        {tid(:campaign_form)}
        novalidate
      >
        <div class="flex max-w-lg flex-col space-y-6">
          <div>
            <label>
              <div class="mb-2">Campaign Name</div>
              <%= text_input(f, :name, required: true, class: "Input") %>
            </label>
            <%= error_tag(f, :name) %>
          </div>

          <div class="flex items-center justify-between">
            <h3 class="text-lg font-bold">Texter Script Steps</h3>

            <button
              type="button"
              class="flex items-center text-red-500"
              phx-click="add-script-message"
              {tid(:add_script_message)}
            >
              <I.plus_circle class="h-5 w-5" />
              <span class="sr-only">Add Script Message</span>
            </button>
          </div>

          <div class="space-y-6">
            <%= for ff <- inputs_for(f, :script_messages) do %>
              <article>
                <div class="mb-2 flex justify-between">
                  <h4 class="font-bold">Step <%= ff.index + 1 %></h4>

                  <button
                    type="button"
                    class="flex items-center space-x-1 text-red-500"
                    phx-click="remove-script-message"
                    phx-value-index={ff.index}
                  >
                    <I.minus_circle class="h-5 w-5" />
                    <span class="sr-only">Remove Script Message</span>
                  </button>
                </div>

                <div class="space-y-2 border-l-2 border-gray-200 pl-2">
                  <label class="block">
                    <div class="mb-2">Report Label</div>
                    <%= text_input(ff, :report_label, required: true, class: "Input") %>
                  </label>
                  <%= error_tag(ff, :report_label) %>

                  <label class="block">
                    <div class="mb-2">Message</div>
                    <div class="flex flex-col">
                      <%= textarea(ff, :message_template,
                        required: true,
                        class: "Input !rounded-b-none",
                        phx_debounce: 100
                      ) %>

                      <output class="rounded-b-lg border border-gray-100 p-2">
                        <%= ff |> input_value(:message_template) |> render_preview(@current_user) %>
                      </output>
                    </div>
                  </label>

                  <div class="flex justify-between">
                    <h4>Survey Responses</h4>

                    <button
                      type="button"
                      class="flex items-center text-red-500"
                      phx-click="add-survey-response"
                      phx-value-index={ff.index}
                    >
                      <I.plus_circle class="h-5 w-5" />
                      <span class="sr-only">Add Survey Response</span>
                    </button>
                  </div>

                  <div class="my-2 space-y-2">
                    <%= for fff <- inputs_for(ff, :survey_options) do %>
                      <div class="hidden"><%= hidden_inputs_for(fff) %></div>
                      <div class="flex items-center space-x-2">
                        <%= text_input(fff, :value, required: true, class: "Input") %>

                        <button
                          type="button"
                          class="flex items-center space-x-1 text-red-500"
                          phx-click="remove-survey-response"
                          phx-value-script-index={ff.index}
                          phx-value-survey-index={fff.index}
                        >
                          <I.minus_circle class="h-5 w-5" />
                          <span class="sr-only">Remove Survey Response</span>
                        </button>
                      </div>
                      <%= error_tag(fff, :value) %>
                    <% end %>
                  </div>
                </div>
              </article>
              <div class="hidden"><%= hidden_inputs_for(ff) %></div>
            <% end %>

            <%= error_tag(f, :script_messages) %>
          </div>

          <section class="mt-6 text-sm">
            <h3 class="mb-2 font-bold">Dynamic script fields:</h3>
            <ul class="list-inside list-disc">
              <li><code>{{contact.first_name}}</code></li>
              <li><code>{{contact.last_name}}</code></li>
              <li><code>{{texter.first_name}}</code></li>
              <li><code>{{texter.last_name}}</code></li>
            </ul>
          </section>

          <label>
            <div class="mb-2">Filter contacts by tag (optional)</div>
            <%= text_input(f, :tag_filters_input,
              class: "Input max-w-xs",
              value: f.source |> get_field(:tag_filters) |> tag_filters_to_string(),
              autocomplete: false,
              autocorrect: false,
              spellcheck: false
            ) %>
          </label>
          <%= error_tag(f, :tag_filters_input) %>

          <section class="h-60 overflow-y-auto text-sm">
            <h3 class="mb-2 font-bold">Selected Contacts:</h3>
            <table class="w-full">
              <thead class="border-b border-gray-400 text-left">
                <tr class="Table-row">
                  <th class="Table-cell">Last Name</th>
                  <th class="Table-cell">First Name</th>
                </tr>
              </thead>
              <tbody>
                <%= for contact <- f.source |> get_field(:tag_filters) |> Contacts.all_matching_filters() do %>
                  <tr class="Table-row">
                    <td class="Table-cell"><%= contact.last_name %></td>
                    <td class="Table-cell"><%= contact.first_name %></td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </section>

          <label>
            <div class="mb-2">Outgoing Phone Number</div>
            <%= select(f, :phone_number, @provisioned_numbers, class: "Input max-w-xs") %>
          </label>
          <%= error_tag(f, :phone_number) %>

          <div class="flex justify-end space-x-4 !mt-12">
            <button class="Btn Btn--primary">Save</button>
          </div>
        </div>
      </.form>
    </.wrapper>
    """
  end

  @break raw("<br>")
  @fake_data %{"contact" => %{"first_name" => "Paul", "last_name" => "Robeson"}}

  defp render_preview(template, %{first_name: first_name, last_name: last_name}) do
    data = Map.put(@fake_data, "texter", %{"first_name" => first_name, "last_name" => last_name})

    case Campaigns.render_message_template(template, data) do
      {:ok, rendered} ->
        rendered |> IO.iodata_to_binary() |> String.split("\n") |> Enum.intersperse(@break)

      {:error, :empty} ->
        raw("&nbsp;")

      {:error, _} ->
        raw(~s(<span class="italic text-red-500">Invalid message</span>))
    end
  end

  defp tag_filters_to_string(filters) do
    Enum.map_join(filters, " ", fn
      %{direction: :exclude, tag: tag} -> "-#{tag}"
      %{direction: :include, tag: tag} -> tag
    end)
  end
end
