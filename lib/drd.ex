defmodule Drd do
  use Application
  import Supervisor.Spec

  def start(_type, _args) do
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
  Initializes the worker with an update offset of o.
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

  def handle_info(:update, offset) do
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

    Process.send_after(self(), :update, 1000)
    reply
  end
end
