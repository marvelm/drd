defmodule UpdateHandler do
  @token Application.get_env(:drd, :token)
  @sendUrl "https://api.telegram.org/bot" <> @token <> "/sendMessage"

  require Logger

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

  defp listen(reply) do
    receive do
      {:hn_ask, story} ->
        reply.("<a href=\"https://news.ycombinator.com/item?id=#{story["id"]}\">#{story["title"]}</a>\n#{story["descendants"]} comments\n#{story["text"]}")
        listen(reply)
      {:hn_top, story} ->
        reply.("<a href=\"#{story["url"]}\">#{story["title"]}</a>\n<a href=\"https://news.ycombinator.com/item?id=#{story["id"]}\">#{story["descendants"]} comments</a>")
        listen(reply)
      {:reddit, stories} ->
        Enum.each stories, fn(story) ->
          reply.("<a href=\"#{story["url"]}\">#{story["title"]}</a>\n<a href=\"https://reddit.com#{story["permalink"]}\">#{story["num_comments"]} comments</a>")
        end
      :stop -> nil
    after
      1_000 -> nil
    end
  end

  def handle(%{"message" => message}) do
    text = String.strip message["text"]
    to = message["from"]["id"]
    reply = &(send_message(to, &1))

    case String.split(text, " ") do
      ["/hn", "ask"] ->
        send spawn(HackerNews, :get_ask_stories, []), self

      ["/hn", "ask", n] ->
        {num, _} = Integer.parse n
        send spawn(HackerNews, :get_ask_stories, [num]), self

      ["/hn", n] ->
        {num, _} = Integer.parse n
        send spawn(HackerNews, :get_top_stories, [num]), self

      ["/hn"] ->
        send spawn(HackerNews, :get_top_stories, []), self

      ["/reddit"] ->
        send self, {:reddit, Reddit.get_subreddit}

      ["/reddit", second_arg] ->
        case Integer.parse(second_arg) do
          {num, _} ->
            send self, {:reddit, Reddit.get_subreddit("all", num)}

          _ ->
            subreddit = second_arg
            send self, {:reddit, Reddit.get_subreddit(subreddit)}
        end

      ["/reddit", subreddit, num] ->
        {num, _} = Integer.parse(num)
        send self, {:reddit, Reddit.get_subreddit(subreddit, num)}

      other ->
        send self, :stop
        Logger.info other
    end

    listen(reply)
  end

  def handle(unmatched_update) do
    IO.inspect unmatched_update
  end
end
