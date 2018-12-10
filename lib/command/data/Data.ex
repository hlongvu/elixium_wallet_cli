defmodule ElixiumWalletCli.Command.Data do
  def setup_cache do
    :ets.new(:key, [:set, :public, :named_table])
  end

  def get_current_key() do
    with [{"current_key", key}] <- :ets.lookup(:key, "current_key") do
#      IO.inspect(key)
      key
    else
      IO.puts("Error loading current key.")
    end
  end

  def set_current_key(key) do
      :ets.insert(:key, {"current_key", key})
  end
end