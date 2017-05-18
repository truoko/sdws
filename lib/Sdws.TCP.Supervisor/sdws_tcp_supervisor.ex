# Top supervisor. Supervises worker processes and listens the TCP socket
defmodule Sdws.TCP.Supervisor do
    use Supervisor
    @name Sdws.TCP.Supervisor

    def start_link(port) do
        Supervisor.start_link(__MODULE__, port, name: @name)
    end

    def init(port) do
        IO.puts("Supervisor: TCP supervisor starting.")
        {:ok, open} = :gen_tcp.listen(port, [:binary, {:packet, 0}, active: true, reuseaddr: true])
        spawn_link(fn -> process_pool() end)
        processes = [worker(Sdws.TCP.Server, [open])]
        supervise(processes, strategy: :simple_one_for_one)
    end

    def start_server_process() do
        #IO.puts("Supervisor: starting TCP server process")
        Supervisor.start_child(@name, [])
    end

    defp process_pool() do
        for _n <- 1..100, do: start_server_process()
    end
end