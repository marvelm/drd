defmodule UpdateHandler do
  @token Application.get_env(:drd, :token)
  @sendUrl "https://api.telegram.org/bot" <> @token <> "/sendMessage"

  require Logger
  require Amnesia

  def send_raw(message) do
    HTTPoison.post!(@sendUrl,
                    Poison.encode!(message),
                    [{"Content-Type", "application/json"}])
  end

  def send_message(to, text, override \\ %{}) do
    send_raw(Dict.merge(%{"chat_id" => to,
                          "text" => text,
                          "parse_mode" => "HTML"},
                        override))
  end

  def format_reply({:hn_ask, story}) do
    "<a href=\"https://news.ycombinator.com/item?id=#{story["id"]}\">#{story["title"]}</a>\n#{story["descendants"]} comments\n#{story["text"]}"
  end

  def format_reply({:hn_top, story}) do
    "<a href=\"#{story["url"]}\">#{story["title"]}</a>\n<a href=\"https://news.ycombinator.com/item?id=#{story["id"]}\">#{story["descendants"]} comments</a>"
  end

  def format_reply({:reddit, story}) do
      "<a href=\"#{story["url"]}\">#{story["title"]}</a>\n<a href=\"https://reddit.com#{story["permalink"]}\">#{story["num_comments"]} comments</a>"
  end

  def listen(reply) do
    receive do
      {:reddit, stories} ->
        Enum.each stories, fn(story) ->
          reply.(format_reply({:reddit, story}))
        end
        listen(reply)
      {other, story} ->
        reply.(format_reply({other, story}))
        listen(reply)
      :stop -> {:ok, :stopped}
    after
      1_000 -> {:ok, :timeout}
    end
  end

  def handle(%{"message" => message}) do
    text = if message["text"] do
      String.strip message["text"]
    else
      ""
    end
    to = message["from"]["id"]

    user = Database.User.read!(to)
    user = if user do
      %{user |
        last_message: text,
        name: message["from"]["first_name"]}
    else
      %Database.User{id: to,
                     last_message: text,
                     name: message["from"]["first_name"]}
    end

    user = if message["location"] do
      %{user |
        longitude: message["location"]["longitude"],
        latitude: message["location"]["latitude"]}
    else
      user
    end
    Database.User.write! user

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

      ["/cbc"] -> nil

      ["/subscribe"] ->
        user = Database.User.read!(to)
        Database.User.write! %{user | subscribed: true}
        reply.("Subscribed")

      ["/unsubscribe"] ->
        user = Database.User.read!(to)
        Database.User.write! %{user | subscribed: false}
        reply.("Unsubscribed")

      ["/start"] ->
        reply.("Hi " <> message["from"]["first_name"] <> " 😁")

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
