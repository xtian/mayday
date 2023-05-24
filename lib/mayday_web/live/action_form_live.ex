defmodule MaydayWeb.ActionFormLive do
  use MaydayWeb, :live_view

  alias Mayday.Actions

  require Logger

  @impl true
  def mount(_, _, socket) do
    {:ok,
     assign(socket,
       changeset: Actions.change_action(%{}),
       page_title: "Submit a New Club Action",
       submitted?: false
     ), layout: {MaydayWeb.LayoutView, :logged_out}}
  end

  @impl true
  def handle_event("validate", %{"action" => params}, socket) do
    if socket.assigns.submitted? do
      {:noreply, assign(socket, :changeset, Actions.change_action(params))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("save", %{"action" => params}, socket) do
    socket =
      case Actions.create_action(params) do
        {:ok, _} ->
          Logger.info("Action submit succeeded: #{inspect(params)}")

          socket
          |> clear_flash(:error)
          |> put_flash(:info, "Action submitted successfully!")
          |> push_navigate(to: Routes.actions_path(socket, :new), replace: true)

        {:error, changeset} ->
          Logger.error("Action submit failed: #{inspect(changeset.errors)}")

          socket
          |> clear_flash(:info)
          |> put_flash(
            :error,
            [
              "The information you provided is invalid. Please fix the ",
              changeset.errors |> length() |> to_string(),
              " errors below."
            ]
          )
          |> assign(changeset: changeset, submitted?: true)
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.wrapper>
      <.form
        :let={f}
        for={@changeset}
        phx-change="validate"
        phx-submit="save"
        novalidate
        x-data
        x-on:submit="window.scrollTo({ top: 0, behavior: 'smooth' })"
      >
        <div class="mx-auto max-w-xl">
          <div class="mb-6 flex items-center space-x-2 text-2xl font-bold text-red-500">
            <h1>Current Actions</h1>
          </div>

          <h1 class="mb-6 text-3xl font-bold">Submit a New Club Action</h1>

          <fieldset class="mb-6">
            <legend class="mb-2 font-bold">Your Contact Information</legend>

            <div class="flex flex-col gap-4 sm:flex-row">
              <label class="flex-1">
                <div class="mb-2">Your Name</div>
                <%= text_input(f, :submitter_name, class: "Input", required: true) %>
                <%= error_tag(f, :submitter_name) %>
              </label>

              <label class="flex-1">
                <div class="mb-2">Your Email</div>
                <%= email_input(f, :submitter_email, class: "Input", required: true) %>
                <%= error_tag(f, :submitter_email) %>
              </label>
            </div>
          </fieldset>

          <fieldset>
            <legend class="mb-2 font-bold">Action Details</legend>

            <div class="mb-6">
              <label class="mb-2 block">
                <div class="mb-2">Name of the Event</div>
                <%= text_input(f, :title, class: "Input", required: true) %>
                <%= error_tag(f, :title) %>
              </label>

              <fieldset class="mb-2 flex flex-col gap-4 sm:flex-row">
                <label class="flex-[2]">
                  <div class="mb-2">Starting Date and Time</div>
                  <div class="flex flex-nowrap items-stretch">
                    <%= datetime_local_input(f, :starts_at, class: "Input !rounded-r-none relative z-10", required: true) %>
                    <div class="flex items-center rounded-r-lg border border-l-0 border-gray-200 p-2 shadow-inner">MT</div>
                  </div>
                  <%= error_tag(f, :starts_at) %>
                </label>

                <label class="flex-1">
                  <div class="mb-2">Ending Time (if known)</div>
                  <div class="flex flex-nowrap items-stretch">
                    <%= time_input(f, :ends_at, class: "Input !rounded-r-none relative z-10") %>
                    <div class="flex items-center rounded-r-lg border border-l-0 border-gray-200 p-2 shadow-inner">MT</div>
                  </div>
                  <%= error_tag(f, :ends_at) %>
                </label>
              </fieldset>

              <div class="flex flex-col gap-4 sm:flex-row">
                <label class="flex-[2] mb-2 block">
                  <div class="mb-2">State</div>
                  <%= select(
                    f,
                    :state,
                    [
                      [key: "Colorado", value: :colorado],
                      [key: "Wyoming", value: :wyoming],
                      [key: "All/National", value: :national]
                    ],
                    class: "Input"
                  ) %>
                  <%= error_tag(f, :state) %>
                </label>

                <label class="mb-2 block flex-1">
                  <div class="mb-2">Cost to Attend (if any)</div>
                  <div class="flex flex-nowrap items-stretch">
                    <div class="flex items-center rounded-l-lg border border-r-0 border-gray-200 p-2 shadow-inner">$</div>
                    <%= currency_number_input(f, :cost_to_attend,
                      class: "Input !rounded-l-none",
                      min: 0,
                      step: 1,
                      decimals: 2
                    ) %>
                  </div>
                  <%= error_tag(f, :cost_to_attend) %>
                </label>
              </div>
            </div>

            <fieldset class="mb-6">
              <legend class="mb-2 font-bold">Location</legend>

              <p class="mb-2">Please provide an address, a URL, or both.</p>

              <label class="flex-1">
                <div class="mb-2">Address</div>
                <%= textarea(f, :address, class: "Input", rows: 2) %>
                <%= error_tag(f, :address) %>
              </label>

              <label class="flex-1">
                <div class="mb-2">URL</div>
                <%= url_input(f, :url, class: "Input") %>
                <%= error_tag(f, :url) %>
              </label>
            </fieldset>

            <label class="mb-6 block">
              <div class="mb-2 font-bold">Sponsor</div>
              <p class="mb-2">Who is organizing the event?</p>
              <%= text_input(f, :sponsor, class: "Input") %>
              <%= error_tag(f, :sponsor) %>
            </label>

            <div class="mb-2 block">
              <label for={input_id(f, :description)} class="mb-2 block font-bold">Description</label>
              <p class="mb-2">
                Please note the following:
                <ul class="mb-4 ml-2 list-inside list-disc">
                  <li>Why is the event taking place?</li>
                  <li>What should we know before we arrive?</li>
                  <li>Will the entire event happen in one place or not? (For example, a march)</li>
                </ul>
              </p>
              <%= textarea(f, :description, class: "Input", rows: 5, required: true) %>
              <%= error_tag(f, :description) %>
            </div>

            <label>
              <div class="mb-2">Additional Comments (optional, will not be made public)</div>
              <%= textarea(f, :comment, class: "Input", rows: 3) %>
              <%= error_tag(f, :comment) %>
            </label>
          </fieldset>

          <div class="mt-12 flex justify-end">
            <button class="Btn Btn--primary">Submit Action</button>
          </div>
        </div>
      </.form>
    </.wrapper>
    """
  end
end
