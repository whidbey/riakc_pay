defmodule RiakcPay.Payment do
  alias RiakcPay.Support.Config

  @payments %{
    "paypal" => RiakcPay.PayPal.Payment,
    "yandexmoney" => RiakcPay.YandexMoney.Payment
  }

  def readable_name(name) do
    payment = @payments[name]
    if nil == payment do
      name
    else
      payment.readable_name()
    end
   
  end

  def purchase(charge,name,namespace,config) do
    payment = @payments[name]
    unless payment do
      raise UndefinedFunctionError , "payment: #{name} is not defined"
    end
    mode = Config.mode()
    gateway = Config.gateway()
    webhook = Config.webhook()
    payment.purchase(charge,mode,namespace,gateway,webhook,config)
  end
  
  def execute(charge,params,name,namespace,config) do
    payment = @payments[name]
    unless payment do
      raise UndefinedFunctionError, "payment: #{name} is not defined"
    end
    mode = Config.mode()
    gateway = Config.gateway()
    webhook = Config.webhook()
    payment.execute(charge,params,mode,namespace,gateway,webhook,config)
  end

  def cancel(charge,params,name,namespace,config) do
    payment = @payments[name]
    unless payment do
      raise UndefinedFunctionError, "payment: #{name} is not defined"
    end
    mode = Config.mode()
    gateway = Config.gateway()
    webhook = Config.webhook()
    payment.cancel(charge,params,mode,namespace,gateway,webhook,config)
  end


end