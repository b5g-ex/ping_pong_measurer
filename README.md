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
iex> MeasurementHelper.start_node("pong@192.168.1.2", :cookie)
iex> PingPongMeasurer.start_pong_processes(_process_count = 100)
```

4. start ping node and start measure

```elixir
iex> MeasurementHelper.start_node("ping@192.168.1.3", :cookie)
$ Node.connect(String.to_atom("pong@192.168.1.2"))
$ MeasurementHelper.start_measurement(_process_count =100)
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ping_pong_measurer>.

