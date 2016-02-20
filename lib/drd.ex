defmodule Drd do
  require Amnesia
  use Application
  import Supervisor.Spec

  def start(_type, _args) do
    Amnesia.start

    Supervisor.start_link(
      [worker(MessageFetcher, [], restart: :transient),
       worker(Notifier, [], restart: :transient)],
      strategy: :one_for_all)
  end
end
