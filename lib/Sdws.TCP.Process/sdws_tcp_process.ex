# TCP Server process
defmodule Sdws.TCP.Server do
    use GenServer

    def start_link(open) do
        GenServer.start_link(__MODULE__, open, [])
    end

    # Send cast to self and start accepting TCP connections
    def init(open) do
        GenServer.cast(self(), {:accept, open})
        {:ok, open}
    end

    # For asynchronous messages
    def handle_cast({:accept, open}, _state) do
        {:ok, socket} = :gen_tcp.accept(open)
        :inet.setopts(socket, [:binary, {:packet,0}, nodelay: true, active: true])
        IO.puts("Server: accepted connection.")
        Sdws.TCP.Supervisor.start_server_process()
        loop(socket)
        {:noreply, open}
    end

    # Receive TCP messages and use a worker process to create a HTTP response
    # After the data is sent back to the requestor, the process terminates
    defp loop(_socket) do
        receive do
            {_tcp, socket, bin} ->
                pid = Enum.random(:pg2.get_members(:worker))
                {:ok, http_message} = GenServer.call(pid, bin)
                IO.puts("Server: replying.")
                :gen_tcp.send(socket, http_message)
                :gen_tcp.close(socket)
                Supervisor.terminate_child(Sdws.TCP.Supervisor, self())
            {_tcp_closed, _socket} ->
                IO.puts("Server: socket closed.")
                Supervisor.terminate_child(Sdws.TCP.Supervisor, self())
        end
    end
end