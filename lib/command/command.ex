defmodule ElixiumWalletCli.Command do
  use GenServer
  require Logger
  alias ElixiumWalletCli.Command.Worker.WalletWorker

  @worker "Elixir.ElixiumWalletCli.Command.Worker"

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    ElixiumWalletCli.Command.Data.setup_cache()
    Process.send_after(self(), :load_wallet, 1_000)
    {:ok, 1}
  end

  defp schedule_work() do
    Process.send_after(self(), :work, 1_00)
  end

  def handle_info(:work, state) do
    IO.puts IO.ANSI.format([:yellow, "Type `help` to see available commands."])
    read_input()

    {:noreply, state}
  end

  defp read_input do
    input = IO.gets("Enter Command: ")
    input
      |> String.trim()
      |> String.split()
      |> run_command()

    schedule_work()
  end

  defp run_command(input) do
    ElixiumWalletCli.Command.Worker.run_command(input)
  end



  # loading wallet on startup
  def handle_info(:load_wallet, state) do
    IO.puts("Specify wallet file name (e.g., MyWallet). If the wallet doesn't exist, it will be created.")
    IO.puts("Wallet is a file name without extension (the .key and .address extensions will be generate automatically).")

    wallet_name = IO.gets("Wallet name (or Ctrl-C to quit): ")
    wallet_name = String.trim(wallet_name)
    wallet_file = "#{wallet_name}.key"

    if File.exists?(wallet_file) do
      Logger.info("Load wallet #{wallet_file}")
      IO.puts("Wallet  #{wallet_file} found!")

      load_wallet(wallet_name)

    else
      confirm_name = IO.gets("No wallet found with name #{wallet_file}. Re-type your wallet name to create a new wallet or else to exit: ")
      confirm_name = String.trim(confirm_name)
      if confirm_name == wallet_name do
        Logger.info("Creating wallet #{wallet_file}")
        IO.puts("Creating wallet #{confirm_name}....")
        IO.puts("The wallet will generate two files: #{confirm_name}.key contains your private key and #{confirm_name}.address contains your address")

        IO.puts("Options:")
        IO.puts("[1]. Generate a new wallet")
        IO.puts("[2]. Import a wallet from seeds")
        IO.puts("[other]. Exit")
        option = IO.gets("Choose option:")
        option = String.trim(option)
        case option do
          "1" -> create_wallet(confirm_name)
          "2" -> load_seed(wallet_name)
          _ -> System.stop(0)
        end
        #create_wallet(confirm_name)

      else
        IO.puts("Wallet name not match. Please try again!")
        System.stop(0)
      end
    end
    schedule_work()
    #    {:stop, :normal, state}
    {:noreply, state}
  end


  defp create_wallet(wallet_name) do
    key_pair = Elixium.KeyPair.create_keypair
    {:ok, private, address} = WalletWorker.create_keyfile(wallet_name, key_pair)
    ElixiumWalletCli.Command.Data.set_current_key(key_pair)
    IO.puts("New keypair generated.")
    IO.puts("Your address: #{address}")

    mnemonic = Elixium.Mnemonic.from_entropy(private)
    IO.puts("Your wallet seed words: `#{mnemonic}`")
    IO.puts("Remember to write down your seed words somewhere safe to backup your wallet.")
  end

  defp load_wallet(wallet_name) do
    with {public, private} <- WalletWorker.load_keyfile(wallet_name) do
      ElixiumWalletCli.Command.Data.set_current_key( {public, private})
      address = Elixium.KeyPair.address_from_pubkey(public)
      IO.puts("Wallet loaded.")
      IO.puts("Your address: #{address}")
    end
  end

  defp load_seed(wallet_name) do
      seeds = IO.gets("Input your seeds: ")
      seeds = String.trim(seeds)
      IO.puts(seeds)
      key_pair = Elixium.KeyPair.gen_keypair(seeds)
      {:ok, private, address} = WalletWorker.create_keyfile(wallet_name, key_pair)
      ElixiumWalletCli.Command.Data.set_current_key(key_pair)
      IO.puts("New keypair imported.")
      IO.puts("Your address: #{address}")
#      mnemonic = Elixium.Mnemonic.from_entropy(private)
#      IO.puts("Your wallet seed words: `#{mnemonic}`")
  end

end