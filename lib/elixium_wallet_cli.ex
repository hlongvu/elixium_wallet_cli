defmodule ElixiumWalletCli do
  use Application

  def start(_type, _args) do
    Elixium.Store.Ledger.initialize()

    # TODO: Make genesis block mined rather than hard-coded
    if !Elixium.Store.Ledger.empty?() do
      Elixium.Store.Ledger.hydrate()
    end

    Elixium.Store.Utxo.initialize()
    Elixium.Store.Oracle.start_link(Elixium.Store.Utxo)
    Elixium.Pool.Orphan.initialize()

    ElixiumWalletCli.Supervisor.start_link()

#    ElixiumWalletCli.Command.Supervisor.start_link()

  end

end
