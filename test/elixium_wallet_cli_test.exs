defmodule ElixiumWalletCliTest do
  use ExUnit.Case
  doctest ElixiumWalletCli

  test "greets the world" do
    assert ElixiumWalletCli.hello() == :world
  end
end
