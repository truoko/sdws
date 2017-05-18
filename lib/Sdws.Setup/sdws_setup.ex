# Setup database
# NOTE: this needs to be run before starting the server
defmodule Sdws.Setup do
    # Setup database for one server, no cluster
    def single_node() do
        :mnesia.start()
        :mnesia.create_table(Notes, [{:attributes, [:id, :timestamp, :note]}, {:type, :ordered_set}])
    end
    # Setup database for a cluster of nodes
    def multi_node(node_list) do
        :mnesia.create_schema(node_list)
        :rpc.multicall(node_list, :mnesia, :start, [])
        :mnesia.create_table(Notes, [{:attributes, [:id, :timestamp, :note]}, {:type, :ordered_set}, {:disc_copies, node_list}])
    end
end