use Mix.Config

config :pca9685,
  devices: [%{bus: "i2c-1", address: 0x42, pwm_freq: 60},
            %{bus: "i2c-1", address: 0x43, pwm_freq: 60}],
  servos: [%{bus: "i2c-1", address: 0x42, channel: 0, position: 90}]#,
  #          %{bus: "i2c-1", address: 0x42, channel: 1, position: 90},
  #          %{bus: "i2c-1", address: 0x42, channel: 2, position: 90},
  #          %{bus: "i2c-1", address: 0x42, channel: 3, position: 90},
  #          %{bus: "i2c-1", address: 0x42, channel: 4, position: 90},
  #          %{bus: "i2c-1", address: 0x42, channel: 5, position: 90},
  #          %{bus: "i2c-1", address: 0x42, channel: 6, position: 90},
  #          %{bus: "i2c-1", address: 0x42, channel: 7, position: 90},
  #          %{bus: "i2c-1", address: 0x42, channel: 8, position: 90},
  #          %{bus: "i2c-1", address: 0x42, channel: 9, position: 90},
  #          %{bus: "i2c-1", address: 0x42, channel: 10, position: 90},
  #          %{bus: "i2c-1", address: 0x42, channel: 11, position: 90},
  #          %{bus: "i2c-1", address: 0x43, channel: 0, position: 90},
  #          %{bus: "i2c-1", address: 0x43, channel: 1, position: 90},
  #          %{bus: "i2c-1", address: 0x43, channel: 2, position: 90},
  #          %{bus: "i2c-1", address: 0x43, channel: 3, position: 90},
  #          %{bus: "i2c-1", address: 0x43, channel: 4, position: 90},
  #          %{bus: "i2c-1", address: 0x43, channel: 5, position: 90},
  #          %{bus: "i2c-1", address: 0x43, channel: 6, position: 90},
  #          %{bus: "i2c-1", address: 0x43, channel: 7, position: 90},
  #          %{bus: "i2c-1", address: 0x43, channel: 8, position: 90},
  #          %{bus: "i2c-1", address: 0x43, channel: 9, position: 90},
  #          %{bus: "i2c-1", address: 0x43, channel: 10, position: 90},
  #          %{bus: "i2c-1", address: 0x43, channel: 11, position: 90}]

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"
