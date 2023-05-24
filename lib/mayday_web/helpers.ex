defmodule MaydayWeb.Helpers do
  use Phoenix.HTML

  import Phoenix.Component

  alias Heroicons, as: I
  alias Phoenix.HTML.Form

  def alert(%{type: type} = assigns) do
    variant =
      case type do
        "error" -> "border-red-500 text-red-500"
        "info" -> "border-slate-600 text-slate-600"
        "notice" -> "border-gray-800 text-gray-800"
      end

    assigns = assigns |> assign(:variant, variant) |> assign_new(:class, fn -> "" end)

    ~H"""
    <%= if @message do %>
      <p
        role="alert"
        class={"#{@variant} #{@class} mb-4 cursor-pointer rounded-lg border px-3 py-2 shadow"}
        phx-click="lv:clear-flash"
        phx-value-key={@type}
      >
        <%= @message %>
      </p>
    <% end %>
    """
  end

  def back_link(assigns) do
    ~H"""
    <.link navigate={@to} class="flex items-center space-x-2 text-red-500">
      <I.arrow_left class="h-4 w-4" />
      <span class="underline">Back</span>
    </.link>
    """
  end

  def currency_number_input(form, field, opts \\ []) do
    opts =
      Keyword.put_new_lazy(opts, :value, fn ->
        case Form.input_value(form, field) do
          value when value in [nil, ""] ->
            nil

          number ->
            number |> Decimal.to_float() |> :erlang.float_to_binary(decimals: 2)
        end
      end)

    Form.number_input(form, field, opts)
  end

  def full_name(%{first_name: first_name, last_name: last_name}) do
    "#{first_name} #{last_name}"
  end

  def enum_select(%{data: %module{}} = form, field, mapper \\ & &1, opts \\ []) do
    select_options = module |> Ecto.Enum.values(field) |> Enum.map(&{mapper.(&1), &1})
    select(form, field, select_options, opts)
  end

  def format_datetime(nil) do
    nil
  end

  def format_datetime(%NaiveDateTime{} = datetime) do
    datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> format_datetime()
  end

  def format_datetime(%DateTime{} = datetime) do
    time_zone = Application.get_env(:mayday, :time_zone, "America/Denver")

    datetime
    |> DateTime.shift_zone!(time_zone)
    |> Calendar.strftime("%m/%d/%y %I:%M%P")
  end

  def tag_filter(assigns) do
    ~H"""
    <div class="rounded bg-gray-200 px-1 text-sm">
      <%= if @direction == :exclude, do: "-" %><%= @tag %>
    </div>
    """
  end

  def wrapper(assigns) do
    ~H"""
    <div class="mx-auto max-w-screen-xl space-y-8 px-4 py-8 xl:px-0">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def wrapper_small(assigns) do
    ~H"""
    <div class="mx-auto max-w-lg space-y-8 px-4 py-12 lg:px-0">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      content_tag(:div, translate_error(error),
        class: "invalid-feedback",
        phx_feedback_for: input_name(form, field)
      )
    end)
  end

  @doc """
  Translates an error message.
  """
  def translate_error({msg, opts}) do
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

  case Mix.env() do
    :test -> def tid(id), do: [{"data-t-#{id}", ""}]
    :dev -> def tid(_), do: []
    :prod -> defmacro tid(_), do: quote(do: [])
  end
end
