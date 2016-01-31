defmodule UpdateHandler do
  @token Application.get_env(:drd, :token)
  @sendUrl "https://api.telegram.org/bot" <> @token <> "/sendMessage"

  defp send_raw(message) do
    HTTPoison.post!(@sendUrl,
                    Poison.encode!(message),
                    [{"Content-Type", "application/json"}])
  end

  defp send_message(to, text, override \\ %{}) do
    send_raw(Dict.merge(%{"chat_id" => to,
                          "text" => text},
                        override))
  end

  def handle(%{"message" => message}) do
    text = message["text"]
    to = message["from"]["id"]
    reply = &(send_message(to, &1))
    cond do
      text == "hi" -> "hello"
      text == "/hn" ->
        Enum.each(HackerNews.get_stories,
          fn(story) ->
            send_message(to,
                         "<a href=\"https://news.ycombinator.com/item?id=#{story["id"]}\">Discussion</a> \n"<>
                           "<a href=\"#{story["url"]}\">#{story["title"]}</a>",
                         %{"parse_mode" => "HTML"})
          end)
      text == "/reddit" ->
        reply.("Reddit not supported yet")
      true ->
        IO.puts "[#{to}] #{text}"
    end
  end

  def handle(unmatched_update) do
    IO.inspect unmatched_update
  end

  def reddit(subreddit \\ "all") do
    url = "https://api.reddit.com/r/" <> subreddit
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        json = Poison.decode! body
        json["data"]["children"]
        "found"

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
        "server side error"
      err ->
        IO.inspect err
        "server side error"
    end
  end

end
