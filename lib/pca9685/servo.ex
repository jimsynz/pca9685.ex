defmodule PCA9685.Servo do
  alias PCA9685.{Device, Commands, Servo}
  use GenServer

  @default_min  150
  @default_max  600

  def start_link(%{device: pid, servo: s}=config) when is_pid(pid) and s >= 0 and s <= 15 do
    GenServer.start_link(Servo, [config])
  end

  def init([%{device: pid}=config]) do
    min  = Map.get(config, :min, @default_min)
    max  = Map.get(config, :max, @default_max)

    config = config
      |> Map.put(:min, min)
      |> Map.put(:max, max)
      |> Map.put(:position, nil)

    Process.link(pid)

    {:ok, config}
  end

  def terminate(:normal, %{device: pid}) do
    Process.unlink(pid)
    :ok
  end

  def terminate(_reason, _state), do: :ok

  def position(pid) when is_pid(pid) do
    GenServer.call(pid, :position)
  end

  def position(pid, degrees) when is_pid(pid) and degrees >= 0 and degrees <= 180 do
    GenServer.call(pid, {:position, degrees})
  end

  def handle_call(:position, _from, %{position: pos}=state) do
    {:reply, pos, state}
  end

  def handle_call({:position, d0}, _from, %{position: d1}=state) when d0 == d1 do
    {:reply, :ok, state}
  end

  def handle_call({:position, d}, _from, %{device: pid, servo: s, min: min, max: max}=state) do
    pwm = scale(d, min, max)
    case Device.issue(pid, fn (pid) -> Commands.led_pwm(pid, s, 0, pwm) end) do
      :ok   -> {:reply, :ok, %{state | position: d}}
      other -> {:reply, other, state}
    end
  end

  defp scale(degrees, min, max) do
    range = max - min
    round((range / 180 * degrees) + min)
  end

end
