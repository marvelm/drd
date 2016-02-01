defmodule HackerNews do
  def get_top_stories(num \\ 3) do
    receive do
      pid ->
        Enum.take(topstories, num)
        |> Enum.each(&(send pid, {:hn_top, item(&1)}))
    end
  end

  def get_ask_stories(num \\ 3) do
    receive do
      pid ->
        Enum.take(askstories, num)
        |> Enum.each(&(send pid, {:hn_ask, item(&1)}))
        send pid, :stop
    end
  end

  defp httpget(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Poison.decode! body
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
        nil
      err ->
        IO.inspect err
        nil
    end
  end

  defp topstories do
    url = "https://hacker-news.firebaseio.com/v0/topstories.json"
    case httpget(url) do
      nil -> []
      storyIds -> storyIds
    end
  end

  defp item(id) do
    url = "https://hacker-news.firebaseio.com/v0/item/#{id}.json"
    httpget(url)
  end

  defp askstories do
    url = "https://hacker-news.firebaseio.com/v0/askstories.json"
    case httpget(url) do
      nil -> []
      askIds -> askIds
    end
  end
end
