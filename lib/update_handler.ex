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

    case String.split(text, " ") do
      ["/hn", "ask"] ->
        Enum.each(HackerNews.get_ask_stories,
          fn(story) ->
            reply.("<a href=\"https://news.ycombinator.com/item?id=#{story["id"]}\">#{story["title"]}</a>\n#{story["descendants"]} comments\n#{story["text"]}")
          end)

      ["/hn", "ask", n] ->
        {num, _} = Integer.parse n
        Enum.each(HackerNews.get_ask_stories(num),
          fn(story) ->
            reply.("<a href=\"https://news.ycombinator.com/item?id=#{story["id"]}\">#{story["title"]}</a>\n#{story["descendants"]} comments\n#{story["text"]}")
          end)

      ["/hn", n] ->
        {num, _} = Integer.parse n
        Enum.each(HackerNews.get_top_stories(num),
          fn(story) ->
            reply.("<a href=\"#{story["url"]}\">#{story["title"]}</a>\n<a href=\"https://news.ycombinator.com/item?id=#{story["id"]}\">#{story["descendants"]} comments</a>")
          end)

      ["/hn"] ->
        Enum.each(HackerNews.get_top_stories,
          fn(story) ->
            reply.("<a href=\"https://news.ycombinator.com/item?id=#{story["id"]}\">#{story["descendants"]} comments</a>\n<a href=\"#{story["url"]}\">#{story["title"]}</a>")
          end)

      ["/reddit"] ->
        Enum.each(Reddit.get_subreddit,
          fn(story) ->
            reply.("<a href=\"#{story["url"]}\">#{story["title"]}</a>\n<a href=\"https://reddit.com#{story["permalink"]}\">#{story["num_comments"]} comments</a>")
          end)

      ["/reddit", second_arg] ->
        case Integer.parse(second_arg) do
          {num, _} ->
            Enum.each(Reddit.get_subreddit("all", num),
              fn(story) ->
                reply.("<a href=\"#{story["url"]}\">#{story["title"]}</a>\n<a href=\"https://reddit.com#{story["permalink"]}\">#{story["num_comments"]} comments</a>")
              end)
          _ ->
            subreddit = second_arg
            Enum.each(Reddit.get_subreddit(subreddit),
              fn(story) ->
                reply.("<a href=\"#{story["url"]}\">#{story["title"]}</a>\n<a href=\"https://reddit.com#{story["permalink"]}\">#{story["num_comments"]} comments</a>")
              end)
        end

      ["/reddit", subreddit, num] ->
        {num, _} = Integer.parse(num)
        Enum.each(Reddit.get_subreddit(subreddit, num),
          fn(story) ->
            reply.("<a href=\"#{story["url"]}\">#{story["title"]}</a>\n<a href=\"https://reddit.com#{story["permalink"]}\">#{story["num_comments"]} comments</a>")
          end)

      other -> IO.inspect other
    end
  end

  def handle(unmatched_update) do
    IO.inspect unmatched_update
  end
end
