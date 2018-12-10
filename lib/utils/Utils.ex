defmodule ElixiumWalletCli.Utils do
  def clear_line_prefix() do
    [IO.ANSI.clear_line, "\r"] |> Enum.join()
  end
end