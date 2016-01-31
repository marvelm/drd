defmodule UpdateHandler do
  @token Application.get_env(:drd, :token)
  @sendUrl "https://api.telegram.org/bot" <> @token <> "/sendMessage"

  def send_message(to, text) do
    HTTPoison.post!(@sendUrl,
                    Poison.encode!(
                      %{"chat_id" => to,
                        "text" => text}),
                    [{"Content-Type", "application/json"}])
  end

  def handle(%{"message" => message}) do
    reply =
      case message["text"] do
        "/reddit" -> "Reddit not supported yet"
        "/hn" -> Enum.each(hackernews, fn(story) -> send_message(message["from"]["id"], story["url"]) end)
        _ ->
          IO.puts "[#{message["from"]["id"]}] #{message["text"]}"
          nil
      end

    unless is_nil(reply) do
      IO.inspect
    end
  end

  def handle(unmatched_update) do
    IO.inspect unmatched_update
  end

  def reddit(subreddit) do
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

  def hackernews do
    Enum.take(topstories, 10)
    |> Enum.map(&(story &1))
  end

  def topstories do
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

  def story(id) do
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
