defmodule UpdateHandler do
  def handle(%{"message" => message}) do
    IO.puts "[#{message["from"]["id"]}] #{message["text"]}"
  end

  def handle(unmatched_update) do
    IO.inspect unmatched_update
  end
end
