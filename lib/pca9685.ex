defmodule PCA9685 do
  use Application
  import Supervisor.Spec, warn: false

  def start(_type, _args) do
    children |> Supervisor.start_link(options)
  end

  def connect(device), do: Supervisor.start_child(PCA9685.Supervisor, [device])

  defp children do
    devices ++ servos
  end

  defp devices do
    :pca9685
    |> Application.get_env(:devices, [])
    |> Enum.map(fn %{bus: bus, address: address}=config ->
      worker(PCA9685.Device, [config], id: {bus, address})
    end)
  end

  defp servos do
    :pca9685
    |> Application.get_env(:servos, [])
    |> Enum.map(fn %{bus: bus, address: address, channel: channel}=config ->
      worker(PCA9685.Servo, [config], id: {bus, address, channel})
    end)
  end

  defp options, do: [strategy: :one_for_one, name: PCA9685.Supervisor]
end
