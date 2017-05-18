# Client module
defmodule Sdws.Client do
    def get(host \\ 'localhost', port \\ 80) do
        {:ok, socket} = :gen_tcp.connect(host, port, [:binary, {:packet, 0}])
        :ok = :gen_tcp.send(socket, "GET / HTTP/1.0\r\n\r\n")
       
        get_data(socket)
    end

    def post(val, host \\ 'localhost', port \\ 80) do
        {:ok, socket} = :gen_tcp.connect(host, port, [:binary, {:packet, 0}])
        :ok = :gen_tcp.send(socket, "POST / HTTP/1.0\r\n\r\n#{val}\r\n\r\n")
       
        get_data(socket)
    end

    defp get_data(_socket) do 
        receive do
            {_tcp, _socket, bin} ->
                IO.write("Client: received data.\n#{bin}")
            {_tcp_closed, _socket} ->
                IO.puts("Client: socket closed.")
        end
    end
end