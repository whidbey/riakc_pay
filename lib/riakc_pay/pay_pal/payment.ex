defmodule RiakcPay.PayPal.Payment do  
	
	alias RiakcPay.Support.Congig

	alias RiakcPay.Operation.Purchase
	alias RiakcPay.PayPal.Operation.Execute

	defp endpoint(mode) do
		if mode == "prod" do
			"https://api.paypal.com/v1/"
		else
			"https://api.sandbox.paypal.com/v1/";
		end
	end

	def purchase(charge,mode,namespace,gateway,webhook,config) do
		endpoint = endpoint(mode)
		client_id = config["client_id"]
		secret = config["secret"]
		max_retries = Congig.max_retries()
		payment = 
			Purchase.assemble(mode,charge)
			|> Purchase.assemble_gateway(mode,charge,gateway)
			|> Purchase.assemble_webhook(mode,charge,webhook)
		Purchase.create(mode,namespace,endpoint,client_id,
			secret,payment,max_retries)
	end

	def execute(charge,params,mode,namespace,gateway,webhook,config) do
		endpoint = endpoint(mode)
		invoice_id = params["paymentId"]
		payer_id = params["PayerID"]

		client_id = config["client_id"]
		secret = config["secret"]
		max_retries = Congig.max_retries()
		Execute.create(mode,namespace,endpoint,client_id,
			secret,invoice_id,payer_id,max_retries)
	end


	def cancel(charge,params,mode,namespace,gateway,webhook,config) do
		{:ok,nil}
	end



end