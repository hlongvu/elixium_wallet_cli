defmodule ElixiumWalletCli.Command.Worker.WalletWorker do
  alias Decimal, as: D
  alias Elixium.Transaction
  alias Elixium.Node.Supervisor, as: Peer
  alias ElixiumWalletCli.Command.Worker.WalletWorker
  alias ElixiumWalletCli.Command.Data
  alias ElixiumWalletCli.Store.FlagUtxo
  alias ElixiumWalletCli.Utils

  require Logger

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
      GenServer.call(:"Elixir.Elixium.Store.UtxoOracle", {:find_by_address, [address]}, 60000)
      |> Enum.reduce(0, fn utxo, acc -> acc + D.to_float(utxo.amount) end)
  end


  def send(to_address, amount) do

    with {:ok, amount} <- Utils.get_float_input(amount),
         true <- Utils.is_valid_address(to_address) do

      amount = D.from_float(amount)

      {public, private} = Data.get_current_key()
      my_address = Elixium.KeyPair.address_from_pubkey(public)
      default_fee = Application.get_env(:elixium_wallet_cli, :default_fee)
      IO.puts("Default transaction fee is: #{default_fee}. If you want to change this transaction's fee, insert it here.")
      fee = IO.gets("Input your desired fee (Number/Enter<Default fee>/<Other to exit>): ")
      with {:ok, final_fee} <- Utils.get_float_input(fee, {:ok, default_fee}) do
          final_fee = D.from_float(final_fee)

          IO.puts("Fee #{final_fee}")

          case build_transaction(private, my_address, to_address, amount, final_fee) do
            :not_enough_balance ->
              IO.puts("Not enough balance")
            :sent ->
              IO.puts("Sent")
            :invalid ->
              IO.puts("Transaction invalid!")
            :error ->
              IO.puts("Gossip error!")
            other ->
              IO.inspect(other)
          end
      else
        err ->
          IO.puts("Input fee is not valid!")
      end
    else
      false ->
        IO.puts("Receiver address is not valid!")
      :invalid ->
        IO.puts("Send amount is not valid!")
    end

  end


  defp find_suitable_inputs(my_address, amount) do
    all_utxos = GenServer.call(:"Elixir.Elixium.Store.UtxoOracle", {:find_by_address, [my_address]}, 60000)
    flag_utxos = FlagUtxo.get_flag_utxos()

    all_utxos -- flag_utxos
    |> Enum.sort(&(:lt == D.cmp(&1.amount, &2.amount)))
    |> Transaction.take_necessary_utxos(amount)
  end


  defp build_transaction(priv, my_address, to_address, amount, fee) do
    transaction = new_transaction(priv, my_address, to_address, amount, fee)
    if transaction !== :not_enough_balance do
      with true <- Elixium.Validator.valid_transaction?(transaction) do
        transaction.inputs |> FlagUtxo.store_flag_utxos()
        if Peer.gossip("TRANSACTION", transaction) == :ok do
          Data.put_transaction(transaction, amount, :pending)
          :sent
        else
          Data.put_transaction(transaction, amount, :error)
          :error
        end
      else
        _err ->
          Data.put_transaction(transaction, amount, :invalid)
          :invalid
      end
    else
      :not_enough_balance
    end
  end

  defp new_transaction(priv, my_address, to_address, amount, fee) do
      case find_suitable_inputs(my_address, D.add(amount, fee)) do
        :not_enough_balance -> :not_enough_balance
        inputs ->
          charge_back = D.sub(Transaction.sum_inputs(inputs), D.add(amount, fee))
          designations =
          if D.cmp(charge_back, D.new(0)) == :gt do
              [%{amount: charge_back, addr: my_address}, %{amount: amount, addr: to_address}]
          else
              [%{amount: amount, addr: to_address}]
          end

          tx =
            %Elixium.Transaction{
              inputs: inputs
            }
          id = Elixium.Transaction.calculate_hash(tx)
          tx = %{tx | id: id}
          transaction = Map.merge(tx, Transaction.calculate_outputs(tx, designations))
          sigs = create_sigs(inputs, transaction, priv)
          Map.put(transaction, :sigs, sigs)
      end
  end

  defp create_sigs(inputs, transaction, priv) do
    digest = Transaction.signing_digest(transaction)
    inputs
    |> Enum.uniq_by(& &1.addr)
    |> Enum.map(fn %{addr: addr} ->
      sig = Elixium.KeyPair.sign(priv, digest)
      {addr, sig}
    end)
  end

end
