defmodule Reddit do
  def get_subreddit(subreddit \\ "all", num \\ 3) do
    receive do
      caller ->
        url = "https://api.reddit.com/r/" <> subreddit
        case Http.get(url) do
          nil -> []
          json ->
            stories = json["data"]["children"]
            Enum.take(stories, num)
            |> Enum.each(&(send caller, {:reddit, &1["data"]})) # Extracts useful data.
            send caller, :stop
        end
    end
  end
end
