defmodule PCA9685.Servo do
  alias PCA9685.{Device, Servo}
  use GenServer

  @default_min  150
  @default_max  600

  @moduledoc """
  Represents a positionable servo connected to a channel
  on a PCA9685 device.
  """

  @doc """
  Connect to the channel via the PCA9695 device.
  """
  @spec start_link(map) :: {:ok, pid}
  def start_link(config), do: GenServer.start_link(Servo, [config])

  @doc false
  def init([%{bus: bus, address: address, channel: channel}=state])
  when is_binary(bus)
  and is_integer(address)
  and is_integer(channel)
  and channel >= 0
  and channel <= 11
  do
    min   = Map.get(state, :min, @default_min)
    max   = Map.get(state, :max, @default_max)

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

  @doc """
  Returns a handy via tuple.

  ## Examples:

      iex> {"i2c-1", 0x42, 0}
      ...> |> PCA9685.Servo.via
      ...> |> PCA9685.Servo.position(90)
  """
  @spec via({bus :: binary, address :: 0..0x7f, channel :: 0..15}) :: {:via, :gproc, term}
  def via({bus, address, channel})
    when is_binary(bus)
    and is_integer(address)
    and is_integer(channel)
    and channel >= 0 and channel <= 15,
    do: {:via, :gproc, gproc_key(bus, address, channel)}

  @doc """
  Returns the current position of the servo.
  """
  @spec position(pid) :: 0..180
  def position(pid), do: GenServer.call(pid, :position)

  @doc """
  Sets the position of the servo.
  """
  @spec position(pid, degrees :: 0..180) :: :ok
  def position(pid, degrees)
    when is_integer(degrees)
    and degrees >= 0
    and degrees <= 180,
    do: GenServer.cast(pid, {:position, degrees})

  @doc """
  Begin the process of sweeping to a new target position over a period of time.

  See `ServoSweep` for more information.
  """
  @spec sweep(pid, degrees :: 0..180, delay :: pos_integer) :: {:ok, pid}
  def sweep(pid, degrees, delay)
    when is_integer(degrees)
    and degrees >= 0
    and degrees <= 180,
    do: PCA9685.ServoSweep.start_link(pid, degrees, delay)

  @doc false
  def handle_call(:position, _from, %{position: position}=state) do
    {:reply, position, state}
  end

  @doc false
  def handle_cast({:position, degrees}, state) do
    state = set_position(state, degrees)
    {:noreply, state}
  end

  defp set_initial_position(%{position: position}=state) do
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
