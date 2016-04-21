defmodule RiakcPay.Support.Config do
  @default_config %{
    host: "127.0.0.1",
    port: 6379,
    database: 0,
    size: 10,
    max_overflow: 5,
    http_timeout: :infinity,
    http_recv_timeout: :infinity,
    max_retries: 3,
    mode: "test",
    gateway: "http://localhost/",
    webhook: "http://localhost/"
  }

  def start_link(opts \\ []) do
    result = Agent.start_link(fn -> %{} end, name: RiakcPay.Support.Config)
    server_opts(opts)
    result
  end

  def pool_opts(opts) do
    size = opts[:size] || get(:size)
    max_overflow = opts[:max_overflow] || get(:max_overflow)
    pool = 
    [
      name: {:local, RiakcPay.Redis.Poolboy},
      worker_module: Redix,
      size: size,
      max_overflow: max_overflow
    ]
    Agent.update(RiakcPay.Support.Config,
      fn(config) ->
        Map.merge(config,%{size: size, max_overflow: max_overflow})
      end)
    pool
  end
  def redis_opts(opts) do
    host = opts[:host] || get(:host)
    port = opts[:port] || get(:port)
    database = opts[:database] || get(:database)
    password = opts[:password] || get(:password)
    redis = 
    [
      host: host,
      port: port,
      database: database,
      password: password
    ]
    Agent.update(RiakcPay.Support.Config,
      fn(config) ->
        Map.merge(config,%{host: host,
          port: port,database: database, password: password})
      end)
    redis
  end

  def server_opts(opts) do
    mode = opts[:mode] || get(:mode)
    gateway = opts[:gateway] || get(:gateway)
    webhook = opts[:webhook] || get(:webhook)
    http_timeout = opts[:http_timeout] || get(:http_timeout)
    http_recv_timeout = opts[:http_recv_timeout] || get(:http_recv_timeout)
    max_retries = opts[:max_retries] || get(:max_retries)
    server = 
    [
      mode: mode,
      gateway: gateway,
      webhook: webhook,
      http_timeout: http_timeout,
      http_recv_timeout: http_recv_timeout,
      max_retries: max_retries
    ]

    Agent.update(RiakcPay.Support.Config,
      fn(config) ->
        Map.merge(config,%{mode: mode,gateway: gateway,webhook: webhook,
          http_timeout: http_timeout, http_recv_timeout: http_recv_timeout,
          max_retries: max_retries})
      end)
    server
  end

  def mode() do
    Agent.get(RiakcPay.Support.Config,
      fn(config)->
        Map.get(config,:mode,"test")
    end)
  end
  def gateway() do
    Agent.get(RiakcPay.Support.Config,
      fn(config)->
        Map.get(config,:gateway,"http://localhost")
    end)
  end
  def webhook() do
    Agent.get(RiakcPay.Support.Config,
      fn(config)->
        Map.get(config,:webhook,"http://localhost")
    end)
  end

  def http_timeout() do
    Agent.get(RiakcPay.Support.Config,
      fn(config)->
        Map.get(config,:http_timeout,:infinity)
    end)
  end

  def http_recv_timeout() do
    Agent.get(RiakcPay.Support.Config,
      fn(config)->
        Map.get(config,:http_recv_timeout,:infinity)
    end)
  end

  def max_retries() do
    Agent.get(RiakcPay.Support.Config,
      fn(config)->
        Map.get(config,:max_retries,3)
    end)
  end

  defp get(key) do
    get(key, Map.get(@default_config, key))
  end

  defp get(key, fallback) do
    Application.get_env(:riakc_pay, key, fallback)
  end

end