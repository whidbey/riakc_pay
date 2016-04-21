defmodule RiakcPay.Gateway.PayPal.Response do

	def handle(response) do
    case response do
      {:ok, %HTTPoison.Response{status_code: 401,  body: body, headers: _headers}} ->
        {:ok, response} = Poison.decode body
        {:auth_error, response}
      {:ok, %HTTPoison.Response{status_code: _, body: body, headers: _headers}} ->
        IO.inspect body
        {:ok, Poison.decode!(body)}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:nok, reason}
    end
  end

  def payer_state(response) do
    payer_state = response["state"]
    if payer_state == "approved" do
      "completed"
    else
      "created"
    end
  end

  def payee_state(response) do
    transactions = response["transactions"]
    [transaction] = transactions
    related_resources = transaction["related_resources"]
    [related_resource] = related_resources
    sale = related_resource["sale"]
    IO.inspect sale
    payee_state = sale["state"]
    case payee_state do
      "completed" ->
        "completed"
      "pending" ->
        "pending"
      _->
        "created"
    end

  end
end