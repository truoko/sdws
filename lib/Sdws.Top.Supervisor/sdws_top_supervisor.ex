# Top supervisor starts and supervises other supervisors
defmodule Sdws.Top.Supervisor do
    use Supervisor
    @name Sdws.Top.Supervisor

    def start_link(port) do
        Supervisor.start_link(__MODULE__, port, name: @name)
    end

    def init(port) do
        IO.puts("Supervisor: top supervisor starting.")
        processes = [supervisor(Sdws.TCP.Supervisor, [port]), supervisor(Sdws.Worker.Supervisor, [])]
        supervise(processes, strategy: :one_for_one)
    end
end