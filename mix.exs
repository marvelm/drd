defmodule Drd.Mixfile do
  use Mix.Project

  def project do
    [app: :drd,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application

  defp applications do
    applications(Mix.env)
  end
  defp applications(:dev) do
    applications(:other) ++ [:remix]
  end
  defp applications(_) do
    [:logger,
     :httpoison,
     :timex]
  end

  #
  # Type "mix help compile.app" for more information
  def application do
    [
      mod: {Drd, []},
      applications: applications]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:httpoison, "~> 0.8.0"},
     {:poison, "~> 2.0"},
     {:amnesia, github: "meh/amnesia", tag: :master},
     {:feeder_ex, github: "manukall/feeder_ex", tag: :master},
     {:remix, "~> 0.0.1", only: :dev},
     {:timex, "~> 1.0.1"}]
  end
end
