# Worker process
defmodule Sdws.Server do
    use GenServer

    def start_link() do
        #IO.puts("Server: starting worker process")
        GenServer.start_link(__MODULE__, [], [])
    end

    def init(_) do
        :pg2.join(:worker, self())
        {:ok, :state}
    end

    # Get messages from TCP processes and respond 
    def handle_call(request, _from, state) do
        data = request
        reply = {:ok, loop(data)}
        {:reply, reply, state}
    end
      
    # Assemble http reply based on received method
    defp loop(bin) do
        case parse_method(bin) do
            "GET" ->
                resource = parse_requested_resource(bin)
                IO.puts("Server: client requested resource: #{resource}")
                case resource do
                    "/" ->
                        create_http_response(200)
                    _ ->
                        case parse_function(resource) do
                            "/add_note" ->
                                if parse_data_type(resource) == "text" do
                                    text = parse_text(resource)
                                    post(text)
                                else
                                    create_http_response(400)
                                end
                            _ -> 
                                create_http_response(404)
                        end
                end
            "POST" ->
                text = parse_message_body(bin)
                post(text)
            "DELETE" ->
                create_http_response(501)
            "HEAD" ->
                create_http_response(501)
            "PUT" ->
                create_http_response(501)
            "LINK" ->
                create_http_response(501)
            "UNLINK" ->
                create_http_response(501)
            _ -> 
                create_http_response(501)
        end
    end

    # Write post requests to the database
    defp post(text) do
        {hours, minutes, seconds} = :erlang.time()
        database_write("#{hours}:#{minutes}:#{seconds}", text)
        create_http_response(204)
    end

    # Create the http message based on status code
    defp create_http_response(status_code) do  
        case status_code do
            200 -> 
                {:atomic, data} = database_read()
        
                http_table = unless data == :"$end_of_table" do
                    list_size = Enum.count(data)
                    create_http_table([], data, list_size, 0)
                else
                    ["<td>1</td><td>n/a</td><td>n/a</td></tr></tr></body></html>\r\n"]
                end
                
                http_message = http_table
                |> List.insert_at(0, "HTTP/1.0 200 OK\r\nContent-Type: text/html; charset=UTF-8\r\n\r\n <!DOCTYPE html><html><head><style type='text/css'> div.size {max-width:1700px;margin: auto;word-wrap: break-word;} table {} td {border: 1px solid black; vertical-align: text-top;} th {border: 1px solid black;text-align: left;background-color: lightgrey;}</style> <title> Notes server </title></head><body><h2>Distributed notes server</h2> <table><tr><th>ID<th>Timestamp</th><th>Note</th></tr><tr>")
                |> List.to_string()

                http_message
            204 ->
                "HTTP/1.0 204 No Content\r\n\r\n"
            404 ->
                "HTTP/1.0 404 Not Found\r\n\r\n"
            400 ->
                "HTTP/1.0 400 Bad Request\r\n\r\n"
            501 -> 
                "HTTP/1.0 501 Not Implemented\r\n\r\n"
            201 -> 
                "HTTP/1.0 201 Created\r\n\r\n"       
            _ ->
                "HTTP/1.0 500 Internal Server Error\r\n\r\n"
        end
    end

    # Recursive function assembles the table displayed on the web site, starting from the end
    defp create_http_table([], data, rows, n) do 
        create_http_table(["</tr></body></html>\r\n"], data, rows-1, n)
    end
    defp create_http_table(list, data, rows, n) when n >= rows do 
        {_, id, time, message} = Enum.at(data, n) |> List.first()
        ["<td>#{id}</td><td>#{time}</td><td>#{message}</td></tr>" | list]
    end
    defp create_http_table(list, data, rows, n) do
        {_, id, time, message} = Enum.at(data, n) |> List.first()
        create_http_table(["<td>#{id}</td><td>#{time}</td><td>#{message}</td></tr>" | list], data, rows, n+1)
    end

    # Read all entries from the database
    defp database_read() do
        case :mnesia.transaction(fn -> :mnesia.last(Notes) end) do
            {:atomic, :"$end_of_table"} ->
                {:atomic, :"$end_of_table"}
            {:atomic, number} ->
                f = fn -> for n <- 1..number, do: :mnesia.read({Notes, n}) end
                :mnesia.transaction(f)
        end
    end

    # Write an entry to the database
    defp database_write(time, text) do
        case :mnesia.transaction(fn -> :mnesia.last(Notes) end) do
            {:atomic, :"$end_of_table"} ->
                f = fn -> :mnesia.write({Notes, 1, time, text}) end
                :mnesia.transaction(f)
            {:atomic, number} ->
                f = fn -> :mnesia.write({Notes, number+1, time, text}) end
                :mnesia.transaction(f)
        end
    end

    # Parsing functions
    defp parse_method(data) do
        String.split(data, " ") |>
        Enum.at(0)
    end

    defp parse_requested_resource(data) do
        String.split(data, " ") |>
        Enum.at(1)
    end

    defp parse_message_body(data) do
        String.split(data, "\r\n") |>
        Enum.filter(&(String.length(&1) > 0)) |> 
        Enum.at(-1)
    end

    defp parse_function(data) do
        String.split(data, "?") |> 
        Enum.at(0)
    end

    defp parse_text(data) do
        String.split(data, "=") |> 
        Enum.at(-1) |>
        String.split("%22") |>
        Enum.at(1) |>
        String.replace("%20", " ")
    end

    defp parse_data_type(data) do
        String.split(data, "?") |>
        Enum.at(-1) |>
        String.split("=") |>
        Enum.at(0)
    end
end