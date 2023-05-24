defmodule MaydayWeb.ActionsLive do
  use MaydayWeb, :live_view

  alias Mayday.Actions

  @impl true
  def mount(_, _, socket) do
    {:ok, assign(socket, actions: Actions.list_actions(), page_title: "Actions")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.wrapper>
      <.back_link to={Routes.dashboard_path(@socket, :index)} />

      <h2 class="text-3xl font-bold"><%= @page_title %></h2>

      <div class="flex flex-wrap">
        <article :for={action <- @actions} class="basis-1/2 rounded-lg border border-gray-400 px-6 py-4 shadow">
          <h3 class="mb-2 text-lg font-bold"><%= action.title %></h3>

          <footer class="my-2">
            Submitted at <%= format_datetime(action.inserted_at) %> by
            <.link href={["mailto:", action.submitter_email]} class="mx-1 text-red-500 underline">
              <%= action.submitter_name %>
            </.link>
          </footer>

          <dl class="space-y-4">
            <div>
              <dt class="mb-2 block font-bold">Time</dt>
              <dd>
                <div><%= Calendar.strftime(action.starts_at, "%A, %B %d") %></div>
                <div>
                  <%= [
                    Calendar.strftime(action.starts_at, "%I:%M %p"),
                    if(action.ends_at, do: ["–", Calendar.strftime(action.ends_at, "%I:%M %p")], else: [])
                  ] %>
                </div>
              </dd>
            </div>

            <div>
              <dt class="mb-2 block font-bold">State</dt>
              <dd><%= action.state %></dd>
            </div>

            <div :if={action.address}>
              <dt class="mb-2 block font-bold">Address</dt>
              <dd><%= action.address %></dd>
            </div>

            <div :if={action.url}>
              <dt class="mb-2 block font-bold">URL</dt>
              <dd><%= action.url %></dd>
            </div>

            <div :if={action.cost_to_attend}>
              <dt class="mb-2 block font-bold">Cost to Attend</dt>
              <dd><%= if action.cost_to_attend, do: "$" %><%= action.cost_to_attend %></dd>
            </div>

            <div>
              <dt class="mb-2 block font-bold">Sponsor</dt>
              <dd><%= action.sponsor %></dd>
            </div>

            <div>
              <dt class="mb-2 block font-bold">Description</dt>
              <dd><%= format_text_block(action.description) %></dd>
            </div>

            <div :if={action.comment}>
              <dt class="mb-2 block font-bold">Comment</dt>
              <dd><%= format_text_block(action.comment) %></dd>
            </div>
          </dl>
        </article>
      </div>
    </.wrapper>
    """
  end

  defp format_text_block(string) do
    string |> String.split("\n") |> Enum.intersperse(raw("<br/>"))
  end
end
