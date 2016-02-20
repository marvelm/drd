defmodule Notifier do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, nil)
  end

  @interval 1000 * 60 * 60 * 5

  def init(state) do
    # Update every 5 hours.
    Process.send_after(self, :update, 0)
    {:ok, state}
  end

  def handle_info(:update, state) do
    Process.send_after(self, :update, @interval)

    send(spawn(HackerNews, :get_top_stories, [2]), self)
    # send(spawn(HackerNews, :get_ask_stories, [1]), self)
    send(self, {:reddit, Reddit.get_subreddit("all", 2)})
    messages = listen(4)

    Database.User.keys!() |> Enum.each(fn key ->
      reply = &(Telegram.send_message(key, &1))
      Enum.each(messages, reply)
    end)

    {:noreply, state}
  end

  def listen(max, messages \\ []) do
    if length(messages) == max do
      messages
    else
      receive do
        {:reddit, stories} ->
          new_messages = Enum.map(stories,
                                  &(UpdateHandler.format_reply({:reddit, &1})))
          listen(max, messages ++ new_messages)
        item ->
          {type, _} = item
          new_message = [UpdateHandler.format_reply(item)]
          listen(max, messages ++ new_message)
      after
        10_000 ->
          messages
      end
    end
  end
end