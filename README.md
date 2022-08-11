# PingPongMeasurer

## Getting Started

1. add this to deps

```elixir
def deps do
  [
    {:ping_pong_measurer, git: "https://github.com/b5g-ex/ping_pong_measurer.git"}
  ]
end
```

2. configure data directory to store measurements

```elixir
config :ping_pong_measurer, :data_directory_path, "path/to/directory"
```

If you use this on Nerves system, the "path/to/directory" must be under the `/data` directory which is rw partition.

3. start pong node first

```elixir
$ iex -S mix
$ System.cmd("epmd", ["-daemon"])
$ Node.start(:"pong@#{pong_node_ip_address}")
$ Node.set_cookie(cookie)
```

4. start ping node and start measure

```elixir
$ iex -S mix
$ System.cmd("epmd", ["-daemon"])
$ Node.start(:"ping@#{ping_node_ip_address}")
$ Node.set_cookie(cookie)
$ Node.connect(:"pong@#{pong_node_ip_address}")
$ MeasurementHelper.start_measurement()
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ping_pong_measurer>.

