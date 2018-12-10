defmodule ElixiumWalletCli.Command.Worker.WalletWorker do
  alias Decimal, as: D
  alias Elixium.Transaction

  def create_keyfile(file_name, {public, private}) do
    write_file("#{file_name}.key", private)
    address = Elixium.KeyPair.address_from_pubkey(public)
    write_file("#{file_name}.address", address)
    {:ok, private, address}
  end

  defp write_file(file, key) do
    File.write(file, key)
  end


  def load_keyfile(filename) do
    with {public, private} <- Elixium.KeyPair.get_from_file("#{filename}.key") do
      {public, private}
    else
      err -> err
    end
  end

  def balance(address) do
    balance =
      GenServer.call(:"Elixir.Elixium.Store.UtxoOracle", {:find_by_address, [address]}, 60000)
      |> Enum.reduce(0, fn utxo, acc -> acc + D.to_float(utxo.amount) end)
  end


  def send(to_address, amount) do
    amount = amount | Float.parse() | D.from_float()

    IO.puts("OK address: #{is_valid_address(to_address)}")
    {public, private} = ElixiumWalletCli.Command.Data.get_current_key()

    address = Elixium.KeyPair.address_from_pubkey(public)
    inputs = find_suitable_inputs(address, amount)

    IO.inspect(inputs)
  end

  defp is_valid_address(address) do
    version = Application.get_env(:elixium_core, :address_version)
    with <<_key_version::bytes-size(3)>> <> addr <- address do
      <<compress_pub_key::bytes-size(33), checksum::binary>> = Base58.decode(addr)
      Elixium.KeyPair.checksum(version, compress_pub_key) == checksum
    else
      err -> false
    end
  end

  defp find_suitable_inputs(my_address, amount) do
    GenServer.call(:"Elixir.Elixium.Store.UtxoOracle", {:find_by_address, [my_address]}, 60000)
    |> Enum.sort(&(:lt == D.cmp(&1.amount, &2.amount)))
    |> Transaction.take_necessary_utxos(amount)
  end


end
