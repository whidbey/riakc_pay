defmodule RiakcPay.PayPal.Operation.Purchase do 
  alias RiakcPay.Support.Http

  alias RiakcPay.PayPal.Response
  alias RiakcPay.PayPal.Authentication
  
  def create(mode,namespace,endpoint,client_id,secret,payment,0) do
    {:error,:max_retries}
  end

  def create(mode,namespace,endpoint,client_id,secret,payment,time) do
    case request(mode,namespace,endpoint,client_id,secret,payment) do
      {:auth_error, _response} ->
        Authentication.clean_headers(mode,namespace)
        create(mode,namespace,endpoint,client_id,secret,payment,time - 1)
      {:error, _reason} ->
        create(mode,namespace,endpoint,client_id,secret,payment,time- 1)
      {:ok, response} ->
        response(mode,response)   
    end 
  end
  
  defp request(mode,namespace,endpoint,client_id,secret,payment) do
    json = Poison.encode!(payment)
    url = endpoint <> "payments/payment"
    headers = Authentication.headers(mode,namespace,endpoint,client_id,secret)
    Http.post(url,headers,json)
    |> Response.handle
  end
  
  defp response(mode,response) do
    params = %{}
    links = response["links"]
    if nil == links do
      {:error,nil}
    else
      link = Enum.find(links,
        fn(link) -> 
          link["rel"] == "approval_url"
        end)
      result = %{
        "channel" => "paypal",
        "redirect" => true,
        "method" => "void",
        "endpoint" => link["href"],
        "params" => params
        }
      {:ok, result,%{"invoice_no" => response["id"]}}
    end
  end

  def assemble_gateway(payment,mode,charge,gateway) do
    charge_id = charge["id"] 
    execute_url = gateway <> "paypal/#{charge_id}/execute"
    cancel_url = gateway <> "paypal/#{charge_id}/cancel"
    Map.put(payment,"redirect_urls",
      %{"return_url" => execute_url,"cancel_url" => cancel_url})
  end

  def assemble_webhook(payment,_mode,_charge,_webhook) do
    payment
  end

  def assemble(mode,charge) do
    
    custom = Poison.encode!(%{"mode" => mode,"charge_id" => charge["id"]})

    payment = %{
      "intent" => "sale",
      "payer" => %{"payment_method" => "paypal"}
      }
    assemble_transactions(payment,charge,custom)
  end

  defp assemble_transactions(payment,charge,custom) do
    transaction = %{
      "amount" => 
        %{
          "total" => charge["amount"],
          "currency" => charge["currency"]
        },
      "description" => charge["subject"],
      "invoice_number" => charge["order_no"],
      "custom" => custom
    }
    transaction = assemble_items(transaction,charge["items"])
    Map.put(payment,"transactions",[transaction])
  end

  defp assemble_items(transaction,items) do
    if nil == items do
      transaction
    else
      assemble = Enum.map(items,fn(item) ->
        %{
            "name" => item["name"],
            "price" =>  item["price"],
            "currency" => item["currency"],
            "quantity" => item["quantity"]
          }
        end)
      Map.put(transaction,"item_list",%{"items" => assemble})
    end
  end

end