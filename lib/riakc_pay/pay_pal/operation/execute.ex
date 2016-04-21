defmodule RiakcPay.PayPal.Operation.Execute do 
  alias RiakcPay.Support.Http

  alias RiakcPay.PayPal.Response
  alias RiakcPay.PayPal.Authentication

  def create(mode,namespace,endpoint,client_id,secret,invoice_id,payer_id,0) do
    {:error,:max_retries}
  end

  def create(mode,namespace,endpoint,client_id,secret,invoice_id,payer_id,time) do
    case request(namespace,endpoint,client_id,secret,invoice_id,payer_id) do
      {:auth_error, _response} ->
        Authentication.clean_headers(mode,namespace)
        create(mode,namespace,endpoint,client_id,secret,invoice_id,payer_id,time - 1)
      {:error, _reason} ->
        create(mode,namespace,endpoint,client_id,secret,invoice_id,payer_id,time - 1)
      {:ok, response} ->
        response(mode,response)
    end
  end
  
  defp request(namespace,endpoint,client_id,secret,invoice_id,payer_id) do
    url = endpoint <> "payments/payment/#{invoice_id}/execute"
    data = Poison.encode!(%{payer_id: payer_id})
    headers = Authentication.headers(namespace,endpoint,client_id,secret)
    Http.post(url,headers,data)
    |> Response.handle

  end

  defp response(mode,response) do
    payer_state = payer_state(response)
    payer_id = payer_id(response)
    if payer_state == "approved" do
      payee_state = payee_state(response)
      {:ok,%{"payer_state" => payer_state,
        "payee_state" => payee_state,"payer_no" => payer_id}}
    else
      {:error,nil}
    end
  end

  defp payer_state(response) do
    payer_state = response["state"]
    if payer_state == "approved" do
      "completed"
    else
      "created"
    end
  end

  defp payer_id(response) do
    payer = response["payer"]
    payer_info = payer["payer_info"]
    payer_info["payer_id"]
  end

  defp payee_state(response) do
    transactions = response["transactions"]
    [transaction] = transactions
    related_resources = transaction["related_resources"]
    [related_resource] = related_resources
    sale = related_resource["sale"]
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