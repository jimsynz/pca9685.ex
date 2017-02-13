defmodule PCA9685.Commands do
  alias PCA9685.Registers
  use Bitwise

  def initialize(pid) do
    with :ok <- all_led_pwm(pid, 0, 0),
         :ok <- output_change(pid, 1),
         :ok <- all_call(pid, 1),
         :ok <- :timer.sleep(5),
         :ok <- sleep(pid, 0),
         :ok <- :timer.sleep(5),
         do: :ok
  end

  @doc """
  RESTART Shows state of RESTART logic.
  """
  def reset(pid), do: pid |> Registers.mode1 |> get_bit(7) |> to_boolean
  def reset!(pid), do: pid |> Registers.mode1(<< 0::unsigned-integer-size(8) >>)

  @doc """
  EXTCLK Use external clock.

  Setting this will put the device to sleep, set the external clock bit and
  awaken it.
  """
  def external_clock(pid), do: pid |> Registers.mode1 |> get_bit(6) |> to_boolean
  def external_clock!(pid) do
    case external_clock(pid) do
      1 -> :ok
      0 ->
        <<reg>> = Registers.mode1(pid)
        reg     = reg ||| (1 <<< 6)
        reg     = reg ||| (1 <<< 4)
        with :ok <- sleep!(pid),
             :ok <- Registers.mode1(pid, <<reg>>),
             do: :ok
    end
  end

  @doc """
  AI Register Auto-Increment
  """
  def auto_increment(pid), do: pid |> Registers.mode1 |> get_bit(5) |> to_boolean
  def auto_increment(pid, value) do
    reg = pid
      |> Registers.mode1
      |> set_bit(7, 0)
      |> set_bit(5, value)
    Registers.mode1(pid, reg)
  end

  @doc """
  SLEEP

  0: Normal mode.
  1: Low power mode. Oscillator off.
  """
  def sleep(pid), do: pid |> Registers.mode1 |> get_bit(4) |> to_boolean
  def sleep!(pid), do: sleep(pid, 1)
  def sleep(pid, i) do
    reg = pid
      |> Registers.mode1
      |> set_bit(7, 0)
      |> set_bit(4, i)
    Registers.mode1(pid, reg)
  end

  @doc """
  SUB1

  0: PCA9685 does not respond to I2C-bus subaddress 1.
  1: PCA9685 responds to I2C-bus subaddress 1.
  """
  def subaddress1(pid), do: pid |> Registers.mode1 |> get_bit(3) |> to_boolean
  def subaddress1(pid, i) do
    reg = pid
      |> Registers.mode1
      |> set_bit(7, 0)
      |> set_bit(3, i)
    Registers.mode1(pid, reg)
  end

  @doc """
  SUB2

  0: PCA9685 does not respond to I2C-bus subaddress 2.
  1: PCA9685 responds to I2C-bus subaddress 2.
  """
  def subaddress2(pid), do: pid |> Registers.mode1 |> get_bit(2) |> to_boolean
  def subaddress2(pid, i) do
    reg = pid
      |> Registers.mode1
      |> set_bit(7, 0)
      |> set_bit(2, i)
    Registers.mode1(pid, reg)
  end

  @doc """
  SUB3

  0: PCA9685 does not respond to I2C-bus subaddress 3.
  1: PCA9685 responds to I2C-bus subaddress 3.
  """
  def subaddress3(pid), do: pid |> Registers.mode1 |> get_bit(1) |> to_boolean
  def subaddress3(pid, i) do
    reg = pid
      |> Registers.mode1
      |> set_bit(7, 0)
      |> set_bit(1, i)
    Registers.mode1(pid, reg)
  end

  @doc """
  ALLCALL

  0: PCA9685 does not respond to LED All Call I2C-bus address.
  1: PCA9685 responds to LED All Call I2C-bus address.
  """
  def all_call(pid), do: pid |> Registers.mode1 |> get_bit(0) |> to_boolean
  def all_call(pid, i) do
    reg = pid
      |> Registers.mode1
      |> set_bit(7, 0)
      |> set_bit(1, i)
    Registers.mode1(pid, reg)
  end

  @doc """
  INVRT

  0: Output logic state not inverted. Value to use when external driver used.
  1: Output logic state inverted. Value to use when no external driver used.
  Applicable when OE = 0.
  """
  def invert(pid), do: pid |> Registers.mode2 |> get_bit(4) |> to_boolean
  def invert(pid, i) do
    reg = pid
      |> Registers.mode2
      |> set_bit(4, i)
    Registers.mode2(pid, reg)
  end

  @doc """
  OCH

  0: Outputs change on STOP command.
  1: Outputs change on ACK.
  """
  def output_change(pid), do: pid |> Registers.mode2 |> get_bit(3) |> to_boolean
  def output_change(pid, i) do
    reg = pid
      |> Registers.mode2
      |> set_bit(3, i)
    Registers.mode2(pid, reg)
  end

  @doc """
  OUTDRV

  0: The 16 LEDn outputs are configured with an open-drain structure.
  1: The 16 LEDn outputs are configured with a totem pole structure.
  """
  def output_driver(pid), do: pid |> Registers.mode2 |> get_bit(2) |> to_boolean
  def output_driver(pid, i) do
    reg = pid
      |> Registers.mode2
      |> set_bit(2, i)
    Registers.mode2(pid, reg)
  end

  @doc """
  OUTNE

  00: When OE = 1 (output drivers not enabled), LEDn = 0.
  01: When OE = 1 (output drivers not enabled):
      LEDn = 1 when OUTDRV = 1
      LEDn = high-impedance when OUTDRV = 0 (same as OUTNE[1:0] = 10)
  1X: When OE = 1 (output drivers not enabled), LEDn = high-impedance.
  """
  def output_enable(pid) do
    <<reg>> = Registers.mode2(pid)
    reg && 0x03
  end

  def output_enable(pid, value) do
    <<reg>> = Registers.mode2(pid)
    reg     = (reg &&& 0xfc) + (value &&& 0x03)
    Registers.mode2(pid, <<reg>>)
  end

  @doc """
  LED(n)_ON & LED(n)_OFF

  Red the current PWM values for LED `n`.
  """
  def led_pwm(pid, n) do
    <<a,b,c,d>> = Registers.led(pid, n)
    on  = decode_led(<<a,b>>)
    off = decode_led(<<c,d>>)
    {on, off}
  end

  @doc """
  LED(n)_ON & LED(n)_OFF

  Write PWM values for LED `n`.
  """
  def led_pwm(pid, n, on, off) do
    on  = encode_led(on)
    off = encode_led(off)
    Registers.led(pid, n, on <> off)
  end

  @doc """
  Read the duty cycle of LED `n`.
  """
  def led_duty(pid, n) do
    case led_pwm(pid, n) do
      {0, 4096}  -> 0
      {4096, 0}  -> 4095
      {_, value} -> value
    end
  end

  @doc """
  Write the duty cycle for LED `n` (0..4095)
  """
  def led_duty(pid, n, value, invert \\ false) when value >= 0 and value <= 4095 do
    value = if invert, do: 4095 - value, else: value
    case value do
      0     -> led_pwm(pid, n, 0, 4096)
      4095  -> led_pwm(pid, n, 4096, 0)
      other -> led_pwm(pid, n, 0, other)
    end
  end


  @doc """
  ALL_LED_ON & ALL_LED_OFF

  Set the `on` and `off` values for all leds.
  """
  def all_led_pwm(pid) do
    <<a,b,c,d>> = Registers.all_led(pid)
    on  = decode_led(<<a,b>>)
    off = decode_led(<<c,d>>)
    {on, off}
  end

  def all_led_pwm(pid, on, off) do
    on  = encode_led(on)
    off = encode_led(off)
    Registers.all_led(pid, on <> off)
  end

  def all_led_duty(pid) do
    case all_led_pwm(pid) do
      {0, 4096}  -> 0
      {4096, 0}  -> 4095
      {_, value} -> value
    end
  end

  def all_led_duty(pid, value, invert \\ false)
  when value >= 0
   and value <= 4095
  do
    value = if invert, do: 4095 - value, else: value
    case value do
      0     -> all_led_pwm(pid, 0, 4096)
      4095  -> all_led_pwm(pid, 4096, 0)
      other -> all_led_pwm(pid, 0, other)
    end
  end

  @doc """
  PRE_SCALE

  Prescaler to program the PWM output frequency (default is 200 Hz)
  """
  def pre_scale(pid) do
    <<reg>> = Registers.pre_scale(pid)
    reg
  end

  def pre_scale(pid, value) do
    Registers.pre_scale(pid, <<value::unsigned-integer-size(8)>>)
  end

  def pwm_freq(pid) do
    prescale = pid |> pre_scale
    (25000000.0 / 4096 / (prescale - 0.5)) |> round
  end

  def pwm_freq(pid, freq) do
    prescale = (25000000.0 / 4096.0 / freq + 0.5) |> round

    with :ok <- sleep(pid, 1),
         :ok <- pre_scale(pid, prescale),
         :ok <- sleep(pid, 0),
         :ok <- :timer.sleep(5),
         :ok <- auto_increment(pid, 1),
         do: :ok
  end

  def decode_led(<< lsb, msb>>) do
    msb = msb &&& 0x0f
    lsb + (msb <<< 8)
  end

  def encode_led(value) when value <= 4096 do
    msb = (value >>> 8) &&& 0x0f
    lsb = value &&& 0xff
    <<lsb, msb>>
  end

  defp get_bit(<<byte>>, bit), do: (byte >>> bit) &&& 0x01
  defp set_bit(<<byte>>, bit, 1), do: <<byte ||| (1 <<< bit)>>
  defp set_bit(<<byte>>, bit, 0), do: <<byte ||| ~~~(1 <<< bit)>>
  defp set_bit(<<byte>>, bit, true), do: <<byte ||| (1 <<< bit)>>
  defp set_bit(<<byte>>, bit, false), do: <<byte ||| ~~~(1 <<< bit)>>

  defp to_boolean(0), do: false
  defp to_boolean(1), do: true
end
