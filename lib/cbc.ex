defmodule Cbc do
  @base_url "http://www.cbc.ca/cmlink/rss-"

  require Logger

  defp gen_url(suffix) do
    @base_url <> suffix
  end

  defp memorable_to_suffix(memorable) do
    case memorable do
      "national" -> "thenational"
      "top" -> "topstories"
      # world
      # canada
      # politics
      # business
      # health
      # arts
      "tech" -> "technology"
      # offbeat
      # sports
      "sport" -> "sports"
      "mlb" -> "sports-mlb"
      "nba" -> "sports-nba"
      "curling" -> "sports-curling"
      "cfl" -> "sports-cfl"
      "nfl" -> "sports-nfl"
      "soccer" -> "sports-soccer"
      "figureskating" -> "sports-figureskating"

      "bc" -> "canada-britishcolumbia"
      "kamloops" -> "canada-kamloops"
      "calgary" -> "canada-calgary"
      "edmonton" -> "canada-edmonton"
      "saskatchewan" -> "canada-saskatchewan"
      "saskatoon" -> "canada-saskatoon"
      "manitoba" -> "canada-manitoba"
      "mb" -> "canada-manitoba"
      "thunderbay" -> "canada-thunderbay"
      "sudbury" -> "canada-sudbury"
      "windsor" -> "canada-windsor"
      "kitchener" -> "canada-kitchenerwaterloo"
      "waterloo" -> "canada-kitchenerwaterloo"
      "toronto" -> "canada-toronto"
      "ottawa" -> "canada-ottawa"
      "montreal" -> "canada-montreal"
      "newbrunswick" -> "canada-newbrunswick"
      "pei" -> "canada-pei"
      "novascotia" -> "canada-novascotia"
      "newfoundland" -> "canada-newfoundland"
      "north" -> "canada-north"
      other -> other
    end
  end

  def get_feed(topic \\ "top", num \\ 3) do
    {:ok, %HTTPoison.Response{body: body}} =
      topic
    |> memorable_to_suffix
    |> gen_url
    |> HTTPoison.get

    {:ok, feed, _} = FeederEx.parse(body)
    receive do
      caller ->
        feed.entries
        |> Enum.take(num)
        |> Enum.each(&(send caller, {:rss, &1}))
    end
  end
end
