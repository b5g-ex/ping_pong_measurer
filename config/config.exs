import Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :ping_pong_measurer, :data_directory_path, Path.join(File.cwd!(), "data")
