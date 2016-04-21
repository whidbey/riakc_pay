defmodule RiakcPay.Redis.RedixPool do
  use Supervisor

  alias RiakcPay.Support.Config

  def start_link(args \\ []) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(args) do
    
    pool_opts = Config.pool_opts(args)
    opts = Config.redis_opts(args)

    children = [
      :poolboy.child_spec(RiakcPay.Redis.Poolboy, pool_opts,opts)
    ]

    supervise(children, strategy: :one_for_one, name: __MODULE__)
  end

  def command(command) do 
    :poolboy.transaction(RiakcPay.Redis.Poolboy, &Redix.command(&1, command))
  end

  def pipeline(commands) do
    :poolboy.transaction(RiakcPay.Redis.Poolboy, &Redix.pipeline(&1, commands))
  end
end
