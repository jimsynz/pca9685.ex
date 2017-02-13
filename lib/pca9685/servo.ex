defmodule PCA9685.Servo do
  alias PCA9685.{Device, Servo}
  use GenServer

  @default_min  150
  @default_max  600

  def start_link(config), do: GenServer.start_link(Servo, [config])

  def init([%{bus: bus, address: address, channel: channel}=state])
  when is_binary(bus)
  and is_integer(address)
  and is_integer(channel)
  and channel >= 0
  and channel <= 11
  do
    min = Map.get(state, :min, @default_min)
    max = Map.get(state, :max, @default_max)

    {pid, _} = :gproc.await({:n, :l, {Device, bus, address}}, 5000)
    Process.link(pid)

    state = state
      |> Map.put(:min, min)
      |> Map.put(:max, max)
      |> Map.put(:pid, pid)

    state = set_initial_position(state)

    :ok = gproc_reg(state)

    {:ok, state}
  end

  def position(bus, address, channel)
    when is_binary(bus)
    and is_integer(address)
    and is_integer(channel)
    and channel >= 0
    and channel <= 11,
    do: position({:via, :gproc, gproc_key(bus, address, channel)})

  def position(pid), do: GenServer.call(pid, :position)

  def position(bus, address, channel, degrees)
    when is_binary(bus)
    and is_integer(address)
    and is_integer(channel)
    and is_integer(degrees)
    and channel >= 0
    and channel <= 11
    and degrees >= 0
    and degrees <= 180,
    do: position({:via, :gproc, gproc_key(bus, address, channel)}, degrees)

  def position(pid, degrees)
    when is_integer(degrees)
    and degrees >= 0
    and degrees <= 180,
    do: GenServer.cast(pid, {:position, degrees})

  def handle_call(:position, _from, %{position: position}=state) do
    {:reply, position, state}
  end

  def handle_cast({:position, degrees}, state) do
    state = set_position(state, degrees)
    {:noreply, state}
  end

  defp set_initial_position(%{pid: pid, position: position, channel: channel}=state) do
    set_position(state, position)
  end

  defp set_initial_position(_state), do: :ok

  defp set_position(%{pid: pid, channel: channel}=state, position) do
    pwm = scale(state, position)
    :ok = Device.channel(pid, channel, 0, pwm)
    Map.put(state, :position, position)
  end

  defp gproc_key(bus, address, channel), do: {:n, :l, {Servo, bus, address, channel}}
  defp gproc_reg(%{bus: bus, address: address, channel: channel}) do
    true = :gproc.reg(gproc_key(bus, address, channel))
    :ok
  end

  defp scale(%{min: min, max: max}, degrees) when is_integer(degrees) and degrees >= 0 and degrees <= 180 do
    range = max - min
    (degrees / 180 * range) + min |> round
  end
end
