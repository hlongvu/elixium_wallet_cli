defmodule ElixiumWalletCli.Utils do
  require Logger

    def clear_line_prefix() do
      [IO.ANSI.clear_line, "\r"] |> Enum.join()
    end

    def get_float_input(str, return_if_empty \\ :invalid) do
      num = String.trim(str)
      case num do
        "" -> return_if_empty
        s ->
          with {value, ""} <- Float.parse(s) do
            {:ok, value}
          else
            err ->
              :invalid
          end
      end
    end

    def is_valid_address(address) do
      version = Application.get_env(:elixium_core, :address_version)
      try do
        with <<_key_version::bytes-size(3)>> <> addr <- address do
          <<compress_pub_key::bytes-size(33), checksum::binary>> = Base58.decode(addr)
          Elixium.KeyPair.checksum(version, compress_pub_key) == checksum
        else
          err ->
            Logger.info("Invalid Receiver Address: #{inspect(err)}")
            false
        end
      rescue
        e ->
          Logger.info("Invalid Receiver Address: #{inspect(e)}")
          false
      end

    end

end