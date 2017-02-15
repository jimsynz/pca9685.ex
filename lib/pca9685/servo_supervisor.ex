defmodule PCA9685.ServoSupervisor do
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
    |> Application.get_env(:servos, [])
    |> Enum.map(fn %{bus: bus, address: address, channel: channel}=config ->
      worker(PCA9685.Servo, [config], id: {bus, address, channel})
    end)
  end

  def options do
    [strategy: :one_for_one, name: __MODULE__]
  end

end
