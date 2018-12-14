defmodule ElixiumWalletCli.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixium_wallet_cli,
      version: "0.1.1",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ElixiumWalletCli, []},
      extra_applications: [
        :ssl,
        :logger,
        :inets,
        :crypto,
        :elixium_core
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixium_core, "~> 0.6.0"},
      {:logger_file_backend, "~> 0.0.10"},
      {:scribe, "~> 0.8"}
    ]
  end
end
