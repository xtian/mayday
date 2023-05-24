defmodule Mayday.HTTPClient do
  @callback post_json(String.t(), [{String.t(), String.t()}], any) ::
              {:ok, Finch.Response.t()} | {:error, Exception.t()}

  def post_json(url, headers, body) do
    request =
      Finch.build(
        :post,
        url,
        [{"content-type", "application/json"} | headers],
        Jason.encode!(body)
      )

    Finch.request(request, Mayday.Finch)
  end
end
