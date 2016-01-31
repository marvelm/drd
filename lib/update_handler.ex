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
                          "text" => text,
                          "parse_mode" => "HTML"},
                        override))
  end

  def handle(%{"message" => message}) do
    text = String.strip message["text"]
    to = message["from"]["id"]
    reply = &(send_message(to, &1))
    cond do
      text == "hi" -> "hello"

      String.starts_with?(text, "/hn") ->
        case String.split(text, " ") do
          ["/hn", "ask"] ->
            Enum.each(HackerNews.get_ask_stories,
              fn(story) ->
                reply.("<a href=\"https://news.ycombinator.com/item?id=#{story["id"]}\">#{story["title"]}</a>\n#{story["tex"]}")
              end)

          ["/hn", "ask", n] ->
            {num, _} = Integer.parse n
            Enum.each(HackerNews.get_ask_stories(num),
              fn(story) ->
                reply.("<a href=\"https://news.ycombinator.com/item?id=#{story["id"]}\">#{story["title"]}</a>\n#{story["tex"]}")
              end)

          ["/hn", n] ->
            {num, _} = Integer.parse n
            Enum.each(HackerNews.get_top_stories(num),
              fn(story) ->
                reply.("<a href=\"https://news.ycombinator.com/item?id=#{story["id"]}\">#{story["descendants"]} comments</a>\n<a href=\"#{story["url"]}\">#{story["title"]}</a>")
              end)

          ["/hn"] ->
            Enum.each(HackerNews.get_top_stories,
              fn(story) ->
                reply.("<a href=\"https://news.ycombinator.com/item?id=#{story["id"]}\">#{story["descendants"]} comments</a>\n<a href=\"#{story["url"]}\">#{story["title"]}</a>")
              end)

          other -> IO.inspect other
        end


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
