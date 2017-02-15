defmodule PCA9685 do
  use Application
  import Supervisor.Spec, warn: false

  def start(_type, _args) do
    children()
    |> Supervisor.start_link(options())
  end

  defp children do
    [supervisor(PCA9685.DeviceSupervisor, []),
     supervisor(PCA9685.ServoSupervisor, [])]
  end

  defp options, do: [strategy: :one_for_one, name: PCA9685.Supervisor]
end
