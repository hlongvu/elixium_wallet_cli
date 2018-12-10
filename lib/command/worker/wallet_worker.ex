defmodule ElixiumWalletCli.Command.Worker.WalletWorker do

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
    {public, private} = Elixium.KeyPair.get_from_file("#{filename}.key")
    {public, private}
  end


end
