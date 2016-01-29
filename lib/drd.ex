defmodule Drd do
  use Application
  import Supervisor.Spec

  def start(_type, _args) do
    Supervisor.start_link(
      [worker(MessageFetcher, [])], strategy: :one_for_all)
  end
end

defmodule MessageFetcher do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  # state is the offset
  def init(_state) do
    Process.send_after(self(), :update, 1000)
    {:ok, 0}
  end

  @token File.read! "token"
  @updateUrl String.strip("https://api.telegram.org/bot"
                          <> @token <> "/getUpdates")

  def handle_info(_, offset) do
    url = @updateUrl <> "?offset=" <> Integer.to_string(offset)

    reply =
      case HTTPoison.get(url) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          json = Poison.decode! body
          updates = json["result"]
          last_update = List.last updates

          next_offset =
            case last_update do
              nil ->
                offset
              _ ->
                IO.inspect last_update
                update_id = last_update["update_id"]
                update_id + 1
            end
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
