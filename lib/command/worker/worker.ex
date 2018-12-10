defmodule ElixiumWalletCli.Command.Worker do
  use GenServer
  require Logger
  alias Decimal, as: D

  alias ElixiumWalletCli.Command.Worker.WalletWorker

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    {:ok, 1}
  end

  def run_command(command) do
    GenServer.call(__MODULE__, {:run_command, command})
  end

  def handle_call({:run_command, command}, _caller, state) do
    IO.inspect command
    handle_command(command)
    {:reply, 1,  state}
  end


  defp handle_command(["help"]) do
    IO.puts "Commands:"
    IO.puts("• help")
    IO.puts("• status")
    IO.puts("• create_wallet <file_name>")
    IO.puts("• load_wallet <file_name>")
    IO.puts("• address")
    IO.puts("• balance")
    IO.puts("• passphrase (`Generate mnemonic passphrase for current wallet`)")
    IO.puts("• send <address> <amount>")
    IO.puts("• exit")
    IO.puts("Type help <command> to see usage.")
  end


  defp handle_command(["status"]) do
    IO.puts("Status:...")

  end

  defp handle_command(["exit"]) do
    System.stop(0)
  end


  defp handle_command(["address"]) do
    {public, private} = ElixiumWalletCli.Command.Data.get_current_key()
    address = Elixium.KeyPair.address_from_pubkey(public)
    IO.puts("Your address: #{address}")
  end

  defp handle_command(["create_wallet", file_name]) do
    key_pair = Elixium.KeyPair.create_keypair
    {:ok, private, address} = WalletWorker.create_keyfile(file_name, key_pair)
    ElixiumWalletCli.Command.Data.set_current_key(key_pair)
    IO.puts("New keypair generated.")
    IO.puts("The working key for wallet now updated.")
    IO.puts("Your address: #{address}")
  end

  defp handle_command(["load_wallet", file_name]) do

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
  end

  defp handle_command(["balance"]) do
    {public, private} = ElixiumWalletCli.Command.Data.get_current_key()
    address = Elixium.KeyPair.address_from_pubkey(public)
    balance =
      GenServer.call(:"Elixir.Elixium.Store.UtxoOracle", {:find_by_address, [address]}, 60000)
      |> Enum.reduce(0, fn utxo, acc -> acc + D.to_float(utxo.amount) end)
    IO.puts("Balance: #{balance}")
  end

  defp handle_command(["passphrase"]) do
    {public, private} = ElixiumWalletCli.Command.Data.get_current_key()
    mnemonic = Elixium.Mnemonic.from_entropy(private)
    IO.puts("Passphrase: `#{mnemonic}`")
    IO.puts("Remember write down your Mnemonic or Private Key somewhere safe to backup your wallet.")
  end

  defp handle_command(["send", address, amount]) do
    IO.puts("Sending #{amount} to #{address}")
  end


  defp handle_command(_other) do
    IO.puts("No matching command.")
  end



end