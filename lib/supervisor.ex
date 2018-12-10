defmodule ElixiumWalletCli.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    children = [
      {Elixium.Node.Supervisor, [:"Elixir.ElixiumWalletCli.PeerRouter"]},
      ElixiumWalletCli.PeerRouter.Supervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
