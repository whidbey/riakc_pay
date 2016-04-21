defmodule RiakcPay.Support.Http do
  alias RiakcPay.Support.Config
  
  def post(url,headers,data,opts \\ []) do
    timeout = Config.http_timeout()
    recv_timeout = Config.http_recv_timeout()
    opts = Enum.contact(opts,[timeout: timeout, recv_timeout: recv_timeout])
    HTTPoison.post(url,data,headers,opts)
  end

end