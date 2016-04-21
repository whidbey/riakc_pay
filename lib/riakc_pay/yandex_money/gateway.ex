defmodule RiakcPay.YandexMoney.Gateway do  


    defp endpoint(mode) do
        if mode == "prod" do
            "https://money.yandex.ru/eshop.xml"
        else
            "https://demomoney.yandex.ru/eshop.xml";
        end
    end

    def purchase(app,config,charge,mode) do
        endpoint = endpoint(mode)

        custom = Poison.encode!(%{"mode" => mode, "charge_id" => charge["id"]})

        params = %{
                    "sum" => charge["amount"],
                    "orderNumber" => charge["order_no"],
                    "customerNumber" => charge["payer_no"],
                    "scid" => config["scid"],
                    "shopid" => config["shopid"],
                    "riakcCustom" => custom }
        {:ok,
            %{
                "invoice" => charge["id"], 
                "mode" => mode,
                "credential" => %{
                    "redirect" => false,
                    "channel" => "yandexmoney",
                    "method" => "POST",
                    "endpoint" => endpoint,
                    "params" => params
                }
            }
        }
    end

end