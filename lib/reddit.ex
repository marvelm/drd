defmodule Reddit do
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

  def get_subreddit(subreddit \\ "all", num \\ 3) do
    url = "https://api.reddit.com/r/" <> subreddit
    case httpget(url) do
      nil -> []
      json ->
        stories = json["data"]["children"]
        Enum.take(stories, num)
        |> Enum.map(&(&1["data"])) # Extracts useful data.
    end
  end
end
