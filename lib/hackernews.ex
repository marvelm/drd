defmodule HackerNews do
  def get_top_stories(num \\ 3) do
    receive do
      caller ->
        Enum.take(topstories, num)
        |> Enum.each(&(send caller, &1))
    end
  end

  def get_ask_stories(num \\ 3) do
    receive do
      caller ->
        Enum.take(askstories, num)
        |> Enum.each(&(send caller, &1))
    end
  end

  defp topstories do
    url = "https://hacker-news.firebaseio.com/v0/topstories.json"
    case Http.get(url) do
      nil -> []
      storyIds -> storyIds
    end
  end

  def item(id) do
    url = "https://hacker-news.firebaseio.com/v0/item/#{id}.json"
    Http.get(url)
  end

  defp askstories do
    url = "https://hacker-news.firebaseio.com/v0/askstories.json"
    case Http.get(url) do
      nil -> []
      askIds -> askIds
    end
  end
end
