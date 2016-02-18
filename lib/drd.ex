defmodule Drd do
  import Supervisor.Spec
  require Amnesia
  require Logger

  def listen(max, messages \\ []) do
    if length(messages) == max do
      messages
    else
      receive do
        {:reddit, stories} ->
          Logger.info "received message reddit"
          new_messages = Enum.map(stories,
                                  &(UpdateHandler.format_reply({:reddit, &1})))
          listen(max, messages ++ new_messages)
        item ->
          {type, _} = item
          Logger.info "received message #{type}"
          new_message = [UpdateHandler.format_reply(item)]
          listen(max, messages ++ new_message)
      after
        10_000 ->
          messages
      end
    end
  end

  def notify_hn do
    send(spawn(HackerNews, :get_top_stories, [2]), self)
    send(spawn(HackerNews, :get_ask_stories, [1]), self)
    send(self, {:reddit, Reddit.get_subreddit("all", 2)})
    messages = listen(3)

    Logger.info(length(messages))
    Database.User.keys!() |> Enum.each(fn key ->
      reply = &(UpdateHandler.send_message(key, &1))
      Enum.each(messages, reply)
    end)

    :timer.sleep(1000 * 60 * 60 * 5)
    notify_hn
  end

  def main do
    Amnesia.start
    spawn(Drd, :notify_hn, [])

    Supervisor.start_link(
      [worker(MessageFetcher, [])], strategy: :one_for_all)
  end
end

defmodule MessageFetcher do
  @moduledoc """
  Worker that retrieves new messages from the Telegram Bot API
  once every second.
  """
  use GenServer

  @doc """
  Initializes the worker with an update offset of 0.
  """
  def start_link do
    GenServer.start_link(__MODULE__, 0)
  end

  # state is the offset
  def init(offset) do
    Process.send_after(self(), :update, 1000)
    {:ok, offset}
  end

  @token Application.get_env(:drd, :token)
  @updateUrl "https://api.telegram.org/bot" <> @token <> "/getUpdates"

  # `handle_info` will increment the offset
  def handle_info(:update, offset) do
    # Calls `handle_info` in 1 second with the offset from `reply`
    Process.send_after(self(), :update, 1000)

    url = @updateUrl <> "?offset=" <> Integer.to_string(offset)

    reply =
      case HTTPoison.get(url) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          json = Poison.decode! body
          updates = json["result"]
          last_update = List.last updates

          next_offset =
            case last_update do
              nil -> offset
              _ ->
                update_id = last_update["update_id"]
                update_id + 1
            end

          Enum.each(updates, &(spawn(UpdateHandler, :handle, [&1])))
          {:noreply, next_offset}

        {:error, %HTTPoison.Error{reason: reason}} ->
          IO.inspect reason
          {:noreply, offset}

        err ->
          IO.inspect err
          {:noreply, offset}
      end

    reply
  end
end
