defmodule PCA9685.DeviceSupervisor do
  use Supervisor

  @moduledoc false

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children()
    |> supervise(options())
  end

  def children do
    :pca9685
    |> Application.get_env(:devices, [])
    |> Enum.map(fn %{bus: bus, address: address}=config ->
      worker(PCA9685.Device, [config], id: {bus, address})
    end)
  end

  def options do
    [strategy: :one_for_one, name: __MODULE__]
  end

end
