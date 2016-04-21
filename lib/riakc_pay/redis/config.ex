defmodule RiakcPay.Redis.Config do
  @default_config %{
    host: "127.0.0.1",
    port: 6379,
    database: 0,
    size: 10,
    max_overflow: 5
  }

  def pool_name(name) do
    "#{name}.Redis.Poolboy" |> String.to_atom
  end
  def pool_opts(opts) do
    size = opts[:size] || get(:size)
    max_overflow = opts[:max_overflow] || get(:max_overflow)
    [
      name: {:local, RiakcPay.Redis.Poolboy},
      worker_module: Redix,
      size: size,
      max_overflow: max_overflow
    ]
  end

  def redid_opts(opts \\ []) do
    host = opts[:host] || get(:host)
    port = opts[:port] || get(:port)
    database = opts[:database] || get(:database)
    password = opts[:password] || get(:password)
    [host: host, port: port, database: database, password: password]
  end

  def get(key) do
    get(key, Map.get(@default_config, key))
  end

  def get(key, fallback) do
    Application.get_env(:riakc_pay, key, fallback)
  end
end