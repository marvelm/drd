defmodule Notifier do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  @interval 1000 * 60 * 60 * 5

  def init(prev_messages) do
    # Send first update after 5 hours
    Process.send_after(self, :update, @interval)
    {:ok, prev_messages}
  end

  def handle_info(:update, prev_messages) do
    Process.send_after(self, :update, @interval)

    send(spawn(HackerNews, :get_top_stories, [2]), self)
    # send(spawn(HackerNews, :get_ask_stories, [1]), self)
    send(spawn(Reddit, :get_subreddit, ["all", 2]), self)
    send(spawn(Cbc, :get_feed, ["manitoba", 3]), self)

    prev_messages = MapSet.new(prev_messages)
    messages = listen(7, []) |>
      MapSet.new |>
      MapSet.difference(prev_messages) |>
      MapSet.to_list

    Database.User.keys!() |> Enum.each(fn key ->
      reply = &(Telegram.send_message(key, &1))
      Enum.each(messages, reply)
    end)

    {:noreply, messages}
  end

  def listen(max, messages) when length(messages) == max do
    messages
  end

  def listen(max, messages) do
    receive do
      item ->
        {type, _} = item
        new_message = [UpdateHandler.format_reply(item)]
        listen(max, messages ++ new_message)
    after
      10_000 ->
      if length(messages) < max do
        Process.send_after(self, :update, 1000 * 60 * 5)
      end
        messages
    end
  end
end
