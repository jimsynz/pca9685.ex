use Mix.Config

config :pca9685,
  # devices: [%{bus: "i2c-1", address: 0x40}]
  devices: [%{bus: "i2c-1", address: 0x42, commands: [:initialize, pwm_freq: 60]}]

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"
