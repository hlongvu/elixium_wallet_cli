defmodule ElixiumWalletCli.Command do
  use GenServer
  require Logger
#  alias ElixiumWalletCli.Command.Worker

  @worker "Elixir.ElixiumWalletCli.Command.Worker"

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    ElixiumWalletCli.Command.Data.setup_cache()
    schedule_work()
    {:ok, %{}}
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


end