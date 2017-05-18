# Sdws

Simple distributed web server developed with Elixir.
Made as a thesis project.

## How to use

Using command line in the working directory use `iex -S mix` to compile and run iex.

Database can be set up using `Sdws.Setup.single_node/0` for a single node.
Or `Sdws.Setup.multi_node/1` for multiple nodes, the function takes a list nodes as an argument.
The database needs to be initiated only once.

After database setup, `Sdws.start/0` runs the server for port 80.
Or `Sdws.start/1` with a port number as an argument