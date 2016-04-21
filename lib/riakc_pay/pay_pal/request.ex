defmodule RiakcPay.Gateway.PayPal.Request do
  defp assemble_items(transaction,items) do
    if nil == items do
      transaction
    else
      items = Poison.decode!(items)
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

  def assemble_payment(app,charge,mode,notify) do
    
    app_id = app["id"]

    execute_url = notify <>"paypal/#{app_id}/#{mode}/" <> charge["id"] <> "/execute"
    cancel_url = notify <> "paypal/#{app_id}/#{mode}/" <> charge["id"] <> "/cancel" 
    
    custom = Poison.encode!(%{"mode" => mode,"charge_id" => charge["id"]})

    payment = %{
      "intent" => "sale",
      "payer" => %{"payment_method" => "paypal"},
      "redirect_urls" => 
        %{
          "return_url" => execute_url,
          "cancel_url" => cancel_url
        }
      }
    assemble_transactions(payment,charge,custom)
  end
end