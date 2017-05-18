# Simple distributed web server
defmodule Sdws do
    def start(port \\ 80) do
        :pg2.create(:worker)
        Sdws.Top.Supervisor.start_link(port)
    end
end