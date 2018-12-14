defmodule ElixiumWalletCli.Store.FlagUtxo do
  use Elixium.Store
  require IEx

  @moduledoc """
    When sending a tx, all inputs in that tx must be flagged as used to prevent double spending
  """

  @store_dir ".flag"
  @ets_name :flag

  @type utxo() :: %{
                    txoid: String.t(),
                    addr: String.t(),
                    amount: number,
                    signature: String.t() | none()
                  }

  @oracle_name String.to_atom("#{__MODULE__}Oracle")

  def initialize do
    initialize(@store_dir)
    :ets.new(@ets_name, [:ordered_set, :public, :named_table])
  end

  @doc """
    Add a utxo to leveldb, indexing it by its txoid
  """
  @spec add_utxo(utxo()) :: :ok | {:error, any}
  def add_utxo(utxo) do
    transact @store_dir do
      &Exleveldb.put(&1, String.to_atom(utxo.txoid), :erlang.term_to_binary(utxo))
    end

    :ets.insert(@ets_name, {utxo.txoid, utxo.addr, utxo})
  end

  @spec remove_utxo(String.t()) :: :ok | {:error, any}
  def remove_utxo(txoid) do
    transact @store_dir do
      &Exleveldb.delete(&1, String.to_atom(txoid))
    end

    :ets.delete(@ets_name, txoid)
  end

  @doc """
    Retrieve a UTXO by its txoid
  """
  @spec retrieve_utxo(String.t()) :: map
  def retrieve_utxo(txoid) do
    case :ets.lookup(@ets_name, txoid) do
      [] ->
        transact @store_dir do
          fn ref ->
            {:ok, utxo} = Exleveldb.get(ref, String.to_atom(txoid))
            :erlang.binary_to_term(utxo)
          end
        end
      [{_txoid, _addr, utxo}] -> utxo
    end
  end

  @doc """
    Check if a UTXO is currently in the pool
  """
  @spec in_pool?(utxo()) :: true | false
  def in_pool?(%{txoid: txoid}), do: retrieve_utxo(txoid) != []

  @spec retrieve_all_utxos :: list(utxo())
  def retrieve_all_utxos do
    # It might be better to get from ets here, but there might be the issue
    # that ets wont have an UTXO that the store does, causing a block to be
    # invalidated somewhere down the line even if the inputs are all valid.
    transact @store_dir do
      &Exleveldb.map(&1, fn {_, utxo} -> :erlang.binary_to_term(utxo) end)
    end
  end

  @spec update_with_transactions(list, list) :: :ok | {:error, any}
  def update_with_transactions(transactions, local_transactions) do
    to_remove = filter_transactions_for_local(transactions, local_transactions)
    to_remove |> Enum.each(&remove_utxo(&1.txoid))
    #to_remove |> Enum.each(&(:ets.delete(@ets_name, &1.txoid)))
  end

  defp filter_transactions_for_local(transactions, local_utxos) do
    transactions
    |> Enum.flat_map(& &1.inputs)
    |> Enum.filter(fn utxo -> Enum.any?(local_utxos, fn l_u -> l_u == utxo end) end)
  end


  def get_flag_utxos() do
    GenServer.call(@oracle_name, {:retrieve_all_utxos, []}, 60000)
  end

  def store_flag_utxos(utxos) do
    utxos |> Enum.each(&GenServer.call(@oracle_name, {:add_utxo, [&1]}, 1000))
  end

  def print_flag_utxos() do
    get_flag_utxos()
    |> IO.inspect()
  end

  def update_confirmed_transaction(transaction) do
    transaction.inputs
    |> Enum.each(
         &GenServer.call(@oracle_name, {:remove_utxo, [&1.txoid]}, 1000)
       )
  end

end
