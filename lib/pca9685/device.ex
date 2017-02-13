defmodule PCA9685.Device do
  alias __MODULE__
  use GenServer
  use Bitwise
  require Logger

# Registers/etc:
  @pca9685_address     0x40
  @mode1               0x00
  @mode2               0x01
  @subadr1             0x02
  @subadr2             0x03
  @subadr3             0x04
  @prescale            0xfe
  @led0_on_l           0x06
  @led0_on_h           0x07
  @led0_off_l          0x08
  @led0_off_h          0x09
  @all_led_on_l        0xfa
  @all_led_on_h        0xfb
  @all_led_off_l       0xfc
  @all_led_off_h       0xfd

# Bits:
  @restart             0x80
  @sleep               0x10
  @allcall             0x01
  @invrt               0x10
  @outdrv              0x04

  def start_link(config), do: GenServer.start_link(Device, [config])

  def init([%{bus: bus, address: address}=state]) do
    with {:ok, pid} <- I2c.start_link(bus, address),
         state      <- Map.put(state, :pid, pid),
         :ok        <- do_set_all_pwm(state, 0, 0),
         :ok        <- I2c.write(pid, <<@mode2, @outdrv>>),
         :ok        <- I2c.write(pid, <<@mode1, @allcall>>),
         :ok        <- :timer.sleep(5),
         <<mode1>>  <- I2c.write_read(pid, <<@mode1>>, 1),
         :ok        <- I2c.write(pid, <<@mode1, (mode1 &&& ~~~(@sleep))>>),
         :ok        <- :timer.sleep(5),
         :ok        <- set_pwm_freq_if_required(state),
         :ok        <- Logger.info("Connected to PCA9685 at #{bus}:0x#{Integer.to_string(address,16)}"),
         :ok        <- gproc_reg(state),
         do: {:ok, state}
  end

  def pwm_freq(pid),
    do: GenServer.call(pid, :pwm_freq)

  def pwm_freq(bus, address)
    when is_binary(bus)
    and is_integer(address),
    do: pwm_freq({:via, :gproc, gproc_key(bus, address)})

  def pwm_freq(pid, hz)
    when is_number(hz),
    do: GenServer.cast(pid, {:pwm_freq, hz})

    def pwm_freq(bus, address, hz)
      when is_binary(bus)
      and is_integer(address)
      and is_number(hz),
      do: pwm_freq({:via, :gproc, gproc_key(bus, address)}, hz)

  def all(pid, on, off)
    when is_integer(on)
    and is_integer(off)
    and on >= 0 and on <= 4096
    and off >= 0 and off <= 4096,
    do: GenServer.cast(pid, {:all, on, off})

  def all(bus, address, on, off)
    when is_binary(bus)
    and is_integer(address)
    and is_integer(on)
    and is_integer(off)
    and on >= 0 and on <= 4096
    and off >= 0 and off <= 4096,
    do: all({:via, :gproc, gproc_key(bus, address)}, on, off)

  def channel(pid, channel_no, on, off)
    when is_integer(channel_no)
    and is_integer(on)
    and is_integer(off)
    and channel_no >= 0 and channel_no <= 11
    and on >= 0 and on <= 4096
    and off >= 0 and off <= 4096,
    do: GenServer.cast(pid, {:channel, channel_no, on, off})

  def channel(bus, address, channel_no, on, off)
    when is_binary(bus)
    and is_integer(address)
    and is_integer(channel_no)
    and is_integer(on)
    and is_integer(off)
    and channel_no >= 0 and channel_no <= 11
    and on >= 0 and on <= 4096
    and off >= 0 and off <= 4096,
    do: channel({:via, :gproc, gproc_key(bus, address)}, channel_no, on, off)

  def handle_call(:pwm_freq, _from, state) do
    hz = Map.get(state, :pwm_freq)
    {:reply, hz, state}
  end

  def handle_cast({:pwm_freq, hz}, %{pid: pid}=state) do
    :ok    = do_set_pwm_freq(pid, hz)
     state = Map.put(state, :pwm_freq, hz)
     {:noreply, state}
  end

  def handle_cast({:all, on, off}, state) do
    :ok = do_set_all_pwm(state, on, off)
    {:noreply, state}
  end

  def handle_cast({:channel, channel_no, on, off}, state) do
    :ok = do_set_pwm(state, channel_no, on, off)
    {:noreply, state}
  end

  defp gproc_reg(%{bus: bus, address: address}) do
    true = :gproc.reg(gproc_key(bus, address))
    :ok
  end
  defp gproc_key(bus, address), do: {:n, :l, {Device, bus, address}}

  defp set_pwm_freq_if_required(%{pwm_freq: hz}=state) when is_number(hz) and hz > 0, do: do_set_pwm_freq(state, hz)
  defp set_pwm_freq_if_required(_state), do: :ok

  defp do_set_all_pwm(%{pid: pid}, on, off) do
    with :ok <- I2c.write(pid, <<@all_led_on_l, on &&& 0xff>>),
         :ok <- I2c.write(pid, <<@all_led_on_h, on >>> 8>>),
         :ok <- I2c.write(pid, <<@all_led_off_l, off &&& 0xff>>),
         :ok <- I2c.write(pid, <<@all_led_off_h, off >>> 8>>),
         do: :ok
  end

  defp do_set_pwm_freq(%{pid: pid}, freq_hz) do
    prescale = 25000000.0
    prescale = prescale / 4096.0
    prescale = prescale / freq_hz
    prescale = prescale - 1

    Logger.debug("Setting PWM frequency to #{freq_hz}hz")
    Logger.debug("Estimated pre-scale: #{prescale}")

    prescale = prescale + 0.5
    prescale = Float.floor(prescale)
    prescale = round(prescale)

    Logger.debug("Final pre-scale: #{prescale}")

    <<old_mode>> = I2c.write_read(pid, <<@mode1>>, 1)
    new_mode = (old_mode &&& 0x7F) ||| 0x10

    :ok = I2c.write(pid, <<@mode1, new_mode>>)
    :ok = I2c.write(pid, <<@prescale, prescale>>)
    :ok = I2c.write(pid, <<@mode1, old_mode>>)
    :ok = :timer.sleep(5)
    :ok = I2c.write(pid, <<@mode1, old_mode ||| 0x80>>)
  end

  defp do_set_pwm(%{pid: pid}, channel, on, off) do
    with :ok <- I2c.write(pid, <<@led0_on_l + 4 * channel, on &&& 0xff>>),
         :ok <- I2c.write(pid, <<@led0_on_h + 4 * channel, on >>> 8>>),
         :ok <- I2c.write(pid, <<@led0_off_l + 4 * channel, off &&& 0xff>>),
         :ok <- I2c.write(pid, <<@led0_off_h + 4 * channel, off >>> 8>>),
         do: :ok
  end

end
