defmodule ElixiumWalletCli.Command.Worker do
  use GenServer
  require Logger
  alias Decimal, as: D
  alias Elixium.Store.Ledger
  alias ElixiumWalletCli.Command.Data
  alias ElixiumWalletCli.Command.Worker.WalletWorker
  alias ElixiumWalletCli.Store.FlagUtxo

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    {:ok, 1}
  end

  def run_command(command) do
    GenServer.call(__MODULE__, {:run_command, command}, :infinity)
  end

  def handle_call({:run_command, command}, _caller, state) do
#    IO.inspect command
    handle_command(command)
    {:reply, 1,  state}
  end


  defp handle_command(["help"]) do
    IO.puts "Commands:"
    IO.puts("• help")
    IO.puts("• status")
    IO.puts("• load_wallet <file_name> (Switch to another wallet)")
    IO.puts("• address")
    IO.puts("• balance")
    IO.puts("• seed (`Generate mnemonic seed for current wallet`)")
    IO.puts("• send <address> <amount>")
    IO.puts("• block <index>")
    IO.puts("• history (`See transactions history`)")
    IO.puts("• debug")
    IO.puts("• exit")
    IO.puts("Type help <command> to see usage.")
  end

  defp handle_command(["status"]) do
    last_block = Ledger.last_block()
    IO.puts("Last block: #{:binary.decode_unsigned(last_block.index)}")
  end

  defp handle_command(["exit"]) do
    System.stop(0)
  end


  defp handle_command(["address"]) do
    {public, private} = Data.get_current_key()
    address = Elixium.KeyPair.address_from_pubkey(public)
    IO.puts("Your address: #{address}")
  end



  defp handle_command(["load_wallet", file_name]) do
    if File.exists?("#{file_name}.key") do
      with {public, private} <- WalletWorker.load_keyfile(file_name) do
        ElixiumWalletCli.Command.Data.set_current_key( {public, private})
        address = Elixium.KeyPair.address_from_pubkey(public)
        IO.puts("New keypair loaded.")
        IO.puts("The working key for wallet now updated.")
        IO.puts("Your address: #{address}")

      else
        err ->
          IO.puts("Error loading wallet. Please try again!")
          IO.inspect(err)

      end
    else
      IO.puts("Wallet does not exist. Please try again!")
    end
  end

  defp handle_command(["balance"]) do
    with {public, private} <- ElixiumWalletCli.Command.Data.get_current_key() do
      address = Elixium.KeyPair.address_from_pubkey(public)
      balance = WalletWorker.balance(address)
      IO.puts("Balance: #{balance}")
    else
     err ->
       wallet_not_loaded()
    end
  end

  defp handle_command(["seed"]) do
    with {public, private} <- ElixiumWalletCli.Command.Data.get_current_key() do
      mnemonic = Elixium.Mnemonic.from_entropy(private)
      IO.puts("Your wallet seed words: `#{mnemonic}`")
      IO.puts("Remember to write down your seed words somewhere safe to backup your wallet.")
    else
      err ->
        wallet_not_loaded()
    end
  end

  defp handle_command(["send", address, amount]) do
    WalletWorker.send(address, amount)
  end


  defp handle_command(["block", index]) do
    {id, _} = Integer.parse(index)
    block = Ledger.block_at_height(id)
    IO.puts("Block at index: #{id}")
    IO.inspect(block)
  end


  defp handle_command(["history"]) do
    IO.puts("Sending history:")
    transactions =
      Data.list_transaction()

    transactions
    |> Enum.map( fn {id, _tx, amount, status} -> %{"TxId" => id, "Amount" => D.to_string(amount), "Status" => status} end)
    |> Scribe.print(data: ["TxId", "Amount", "Status"])

  end

  defp handle_command(["debug"]) do
    transactions =
      Data.list_transaction()

    IO.puts("Sending history:")
    IO.inspect(transactions)

    IO.puts("Flaged UTXOs:")
    FlagUtxo.print_flag_utxos()
  end

  defp handle_command(_other) do
    IO.puts("No matching command.")
  end


  defp wallet_not_loaded() do
    IO.puts("Please specify a working wallet with command: create_wallet or load_wallet first.")
  end

end