defmodule FixApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :fix_api,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ssl, :inets]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:certifi, "~> 2.12.0"},
      {:ed25519, "~> 1.4"},
      {:sweet_xml, "~> 0.7.4"},
      {:timex, "~> 3.7"},
      {:phoenix_pubsub, "~> 2.1"}
    ]
  end
end
