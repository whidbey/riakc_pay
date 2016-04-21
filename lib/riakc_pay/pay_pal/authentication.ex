defmodule RiakcPay.PayPal.Authentication do

  alias RiakcPay.Redis.RedixPool, as: Redis

  alias RiakcPay.PayPal.Response

  @doc """
  Auth Headers needed to make a request to paypal.
  """
  def headers(endpoint,app_id,client_id,secret) do
   	Enum.concat(request_headers, authorization_header(endpoint,app_id,client_id,secret))
  end

  def clean_headers(endpoint,app_id) do
    key = token_key(endpoint,app_id)
    Redis.command( ~w(DEL #{key}))
  end

  defp authorization_header(endpoint,app_id,client_id,secret) do
    [{"Authorization", "Bearer " <>  token(endpoint,app_id,client_id,secret)}]
  end
  
  defp request_headers() do
  	[{"Accept", "application/json"}, {"Content-Type", "application/json"}]
  end

  defp basic_headers() do
  	[{"Accept", "application/json"}, {"Content-Type", "application/x-www-form-urlencoded"}]
  end

  @doc """
    Auth Token
  """

  defp token(endpoint,app_id,client_id,secret) do
    key = token_key(endpoint,app_id)
    case Redis.command( ~w(GET #{key})) do
      {:ok,token} ->
        if nil != token do
          token
        else
          request_token(endpoint,app_id,client_id,secret)
        end
      {:error,_any} ->
        request_token(endpoint,app_id,client_id,secret)
    end
  end

  defp request_token(endpoint,app_id,client_id,secret) do
    hackney = [basic_auth: {client_id, secret}]
    HTTPoison.post(endpoint <> "oauth2/token", "grant_type=client_credentials", basic_headers, [ hackney: hackney ])
    |> Response.handle
    |> parse_token
    |> update_token(endpoint,app_id)
  end

  
  defp update_token({:ok, access_token, expires_in},endpoint,app_id) do
    key = token_key(endpoint,app_id)
    r = Redis.command(~w(SETEX #{key} #{expires_in} #{access_token}))
    access_token
  end

  defp parse_token ({:ok, response}) do
    {:ok, response["access_token"], response["expires_in"]}
  end

  defp token_key(app_id,endpoint) do
    "riakc_pay:#{app_id}:paypal:#{endpoint}:token"
  end


end
