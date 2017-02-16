# PCA9685

This is a *simple* elixir library for controlling servos or LEDs with the
[NXP PCA9685 16 channel i2c PWM controller](http://www.nxp.com/products/interfaces/ic-bus-portfolio/ic-led-display-control/16-channel-12-bit-pwm-fm-plus-ic-bus-led-controller:PCA9685).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `pca9685` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:pca9685, "~> 0.1.0"}]
    end
    ```

  2. Ensure `pca9685` is started before your application:

    ```elixir
    def application do
      [applications: [:pca9685]]
    end
    ```

## Usage

Add your device(s) to your project's config:

```elixir
config :pca9685,
        devices: [%{bus: "i2c-1", address: 0x40}]
```

You can optionally specify a PWM frequency to configure at startup, useful if you're driving servos:

```elixir
config :pca9685,
        devices: [%{bus: "i2c-1", address: 0x40, pwm_freq: 60}]
```

You can use the `PCA9685.Device` API to manipuate the device's outputs, for example:

```elixir
# Set the duty cycle for all channels on device "i2c-1:0x40" to 0:150:
PCA9685.Device.all("i2c-1", 0x40, 0, 150)
```

```elixir
# Set the duty cycle for an individual channel:
PCA9685.Device.all("i2c-1", 0x40, 0, 0, 150)
```

Additionally, if you have servos connected and want to control then individually you
can add servos to your configuration as below;

```elixir
config :pca9685,
        servos: [%{bus: "i2c-1", address: 0x42, channel: 0, position: 90, min: 150, max: 600}]
```

And then manipulate them with the `PCA9685.Servo` API.

The `position` key is optional, and sets the initial starting position of the servo (in degrees between 0 and 180).
The `min` and `max` keys are also optional, and will default to a duty cycle of `0:150` and `0:600` respectively, you will most likely need to tune these values for each type of servo you have connected.  Sorry about that.

## Thanks

Thanks to [Adafruit](https://www.adafruit.com/) for their Python and Arduino libraries, from which this code is heavily influenced.

