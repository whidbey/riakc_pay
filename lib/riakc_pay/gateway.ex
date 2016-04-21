defmodule RiakcPay.Gateway do
  @gateways %{
    "paypal" => RiakcPay.PayPal.Gateway,
    "yandexmoney" => RiakcPay.YandexMoney.Gateway
  }

end