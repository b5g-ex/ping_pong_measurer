# PingPongMeasurer

```
$ iex --name ping@[ip address] --cookie [cookie] -S mix
```

## Getting Started

```elixir
def deps do
  [
    {:ping_pong_measurer, git: "https://github.com/b5g-ex/ping_pong_measurer.git"}
  ]
end
```

```elixir
config :ping_pong_measurer, :data_directory_path, "path/to/directory"
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ping_pong_measurer>.

