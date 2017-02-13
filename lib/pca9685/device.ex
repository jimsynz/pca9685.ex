defmodule PCA9685.Device do
  alias PCA9685.{Device, Commands}
  use GenServer
  require Logger

  def start_link(device), do: GenServer.start_link(Device, [device])

  def init([%{bus: bus, address: address}=state]) do
    {:ok, pid} = I2c.start_link(bus, address)
    state      = Map.put(state, :i2c, pid)


    :ok = Commands.reset!(pid)
    apply_commands(state)

    Logger.info("Connecting to PCA9685 device #{device_name state}")

    {:ok, state}
  end

  def terminate(_reason, %{i2c: pid}=state) do
    Logger.info("Disconnecting from PCA9685 device #{device_name state}")
    I2c.release(pid)
  end

  def issue(pid, callback) when is_function(callback, 1) do
    GenServer.call(pid, {:issue, callback})
  end

  def handle_call({:issue, callback}, _from, %{i2c: pid}=state) do
    {:reply, callback.(pid), state}
  end

  defp device_name(%{bus: bus, address: address}), do: "#{bus}:#{i2h address}"
  defp i2h(i), do: "0" <> Integer.to_string(i, 16)

  defp apply_commands(%{commands: commands, i2c: pid}) when is_list(commands) do
    Enum.reduce(commands, :ok, fn
      _, {:error, _}=error ->
        error
      command, :ok when is_atom(command) ->
        apply(Commands, command, [pid])
      {command, args}, :ok when is_atom(command) and is_list(args) ->
        apply(Commands, command, [pid | args])
      {command, arg}, :ok when is_atom(command) ->
        apply(Commands, command, [pid, arg])
  end)
end

  defp apply_commands(_state), do: :ok
end
