# Worker supervisor
defmodule Sdws.Worker.Supervisor do
    use Supervisor
    @name Sdws.Worker.Supervisor

    def start_link do
        Supervisor.start_link(__MODULE__, [], name: @name)
    end

    def init([]) do
        IO.puts("Supervisor: worker supervisor starting.")
        processes = for n <- 1..100 do 
            worker(Sdws.Server, [], id: {:worker_process, n})
        end
        supervise(processes, strategy: :one_for_one)
    end
end