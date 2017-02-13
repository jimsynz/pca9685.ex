defmodule PCA9685 do
  use Application

  def start(_type, _args) do
    {:ok, pid} = children |> Supervisor.start_link(options)

    #    Enum.each(Application.get_env(:pca9685, :devices, []), &connect(&1))

    {:ok, pid}
  end

  def connect(device), do: Supervisor.start_child(PCA9685.Supervisor, [device])

  defp children do
    import Supervisor.Spec, warn: false
    [worker(PCA9685.Device, [])]
  end

  defp options, do: [strategy: :simple_one_for_one, name: PCA9685.Supervisor]
end
