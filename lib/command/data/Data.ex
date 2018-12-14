defmodule ElixiumWalletCli.Command.Data do
  require Logger
  alias ElixiumWalletCli.Store.FlagUtxo

  def setup_cache do
    :ets.new(:key, [:set, :public, :named_table])
    :ets.new(:transactions, [:set, :public, :named_table])
  end

  def get_current_key() do
    with [{"current_key", key}] <- :ets.lookup(:key, "current_key") do
#      IO.inspect(key)
      key
    end
  end

  def set_current_key(key) do
      :ets.insert(:key, {"current_key", key})
  end


  def put_transaction(transaction, amount, status) do
    :ets.insert(:transactions, {transaction.id, transaction, amount, status})
  end

  def get_transaction(transaction_id) do
    with [{_transaction_id, tx, amount, status}] <- :ets.lookup(:transactions, transaction_id) do
      {tx, amount, status}
    end
  end

  def update_confirmed_transaction(transaction) do
    with [{transaction_id, tx, amount, status}] <- :ets.lookup(:transactions, transaction.id) do
      if (status == :pending) do
        Logger.info("Confirmed transaction #{transaction_id}")
        put_transaction(tx, amount, :confirmed)
        # if confirmed, update the flag_utxos store
        FlagUtxo.update_confirmed_transaction(tx)
      end
    end
  end

  def list_transaction() do
    :ets.match_object(:transactions,  {:"_", :"_", :"_", :"_"})
  end

  def get_pending_transactions do
    :ets.match_object(:transactions,  {:"_", :"_", :"_", :pending})
  end

end