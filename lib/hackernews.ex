defmodule HackerNews do
  def get_stories do
    Enum.take(topstories, 10)
    |> Enum.map(&(story &1))
  end

  defp topstories do
    url = "https://hacker-news.firebaseio.com/v0/topstories.json"
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Poison.decode! body
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
        []
      err ->
        IO.inspect err
        []
    end
  end

  defp story(id) do
    url = "https://hacker-news.firebaseio.com/v0/item/#{id}.json"
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
end
