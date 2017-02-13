defmodule PCA9685.Registers do

  # Luckily, all registers on this part are read-write. Makes life simpler.

  %{
    mode1:            {0x00, 1},
    mode2:            {0x01, 1},
    subaddress1:      {0x02, 1},
    subaddress2:      {0x03, 1},
    subaddress3:      {0x04, 1},
    all_call_address: {0x05, 1},
    all_led:          {0xfa, 4},
    pre_scale:        {0xfe, 1},
    test_mode:        {0xff, 1}
  }
  |> Enum.each(fn {fname, {reg, len}} ->
    def unquote(fname)(pid),      do: read_register(pid, unquote(reg), unquote(len))
    def unquote(fname)(pid, buf), do: write_register(pid, unquote(reg), buf)
  end)

  def led(pid, n) do
    reg = 0x06 + (n * 4)
    read_register(pid, reg, 4)
  end

  def led(pid, n, buf) do
    reg = 0x06 + (n * 4)
    write_register(pid, reg, buf)
  end

  defp read_register(pid, register, bytes) do
    with :ok   <- I2c.write(pid, <<register>>),
         value <- I2c.read(pid, bytes),
         do: value
  end

  defp write_register(pid, register, buf), do: I2c.write(pid, <<register>> <> buf)
end
