defmodule Drd do
  import Supervisor.Spec
  require Amnesia
  require Logger

  def main do
    Amnesia.start

    Supervisor.start_link(
      [worker(MessageFetcher, [], restart: :transient),
       worker(Notifier, [], restart: :transient)],
      strategy: :one_for_all)
  end
end
