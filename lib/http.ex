defmodule Http do
  def get(url) do
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
