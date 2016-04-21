defmodule RiakcPay do
  use Application

  def start(_, _) do
   import Supervisor.Spec, warn: false

   children = [
      # Start the endpoint when the application starts
      # Here you could define other workers and supervisors as children
      # worker(RiakcApi.Worker, [arg1, arg2, arg3]),
      supervisor(RiakcPay.Redis.RedixPool, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [
      strategy: :one_for_one,
      name: RiakcPay.Supervisor,
      max_restarts: 20,
      max_seconds: 5
    ]
    Supervisor.start_link(children, opts)
  end
end
