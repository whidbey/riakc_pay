defmodule RiakcPay.Gateway.PayPal.Response do

	def handle(response) do
    case response do
      {:ok, %HTTPoison.Response{status_code: 401,  body: body, headers: _headers}} ->
        {:ok, response} = Poison.decode body
        {:auth_error, response}
      {:ok, %HTTPoison.Response{status_code: _, body: body, headers: _headers}} ->
        {:ok, Poison.decode!(body)}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
  
end