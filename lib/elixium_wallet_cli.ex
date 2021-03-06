defmodule ElixiumWalletCli do
  use Application

  @commander :"Elixir.ElixiumWalletCli.Command.Supervisor"
  def start(_type, _args) do
    Elixium.Store.Ledger.initialize()

    # TODO: Make genesis block mined rather than hard-coded
    if !Elixium.Store.Ledger.empty?() do
      Elixium.Store.Ledger.hydrate()
    end

    Elixium.Store.Utxo.initialize()
    ElixiumWalletCli.Store.FlagUtxo.initialize()
    Elixium.Store.Oracle.start_link(Elixium.Store.Utxo)
    Elixium.Store.Oracle.start_link(ElixiumWalletCli.Store.FlagUtxo)
    Elixium.Pool.Orphan.initialize()

    ElixiumWalletCli.Supervisor.start_link()



  end


  def start_command() do
        case Process.whereis(@commander) do
          nil ->
            IO.puts("\nStarting Commander")
            ElixiumWalletCli.Command.Supervisor.start_link()
          pid ->
            IO.puts("Commander is started")
            pid
        end
  end

end
