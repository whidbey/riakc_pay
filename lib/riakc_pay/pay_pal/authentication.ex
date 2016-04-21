defmodule RiakcPay.PayPal.Authentication do

  alias RiakcPay.Redis.RedixPool, as: Redis

  alias RiakcPay.PayPal.Response
  alias RiakcPay.Support.Http

  @doc """
  Auth Headers needed to make a request to paypal.
  """
  def headers(mode,namespace,endpoint,client_id,secret) do
   	Enum.concat(request_headers(), 
      authorization_header(mode,namespace,endpoint,client_id,secret))
  end

  def clean_headers(mode,namespace) do
    key = token_key(mode,namespace)
    Redis.command( ~w(DEL #{key}))
  end

  defp authorization_header(mode,namespace,endpoint,client_id,secret) do
    [{"Authorization", "Bearer " <>  token(mode,namespace,endpoint,client_id,secret)}]
  end
  
  defp request_headers() do
  	[{"Accept", "application/json"}, {"Content-Type", "application/json"}]
  end

  defp basic_headers() do
  	[{"Accept", "application/json"}, {"Content-Type", "application/x-www-form-urlencoded"}]
  end


  defp token(mode,namespace,endpoint,client_id,secret) do
    key = token_key(mode,namespace)
    case Redis.command( ~w(GET #{key})) do
      {:ok,token} ->
        if nil != token do
          token
        else
          request(mode,namespace,endpoint,client_id,secret)
        end
      {:error,_any} ->
        request(mode,namespace,endpoint,client_id,secret)
    end
  end

  defp request(mode,namespace,endpoint,client_id,secret) do
    hackney = [basic_auth: {client_id, secret}]
    url = endpoint <> "oauth2/token"
    data =  "grant_type=client_credentials"
    Http.post(url,basic_headers(),data,[hackney: hackney])
    |> Response.handle
    |> parse
    |> update(mode,namespace)
  end

  defp parse ({:ok, response}) do
    {:ok, response["access_token"], response["expires_in"]}
  end
  
  defp update({:ok, access_token, expires_in},mode,namespace) do
    key = token_key(mode,namespace)
    Redis.command(~w(SETEX #{key} #{expires_in} #{access_token}))
    access_token
  end

  defp token_key(mode,namespace) do
    "riakc_pay:paypal:token:#{mode}:#{namespace}"
  end


end
