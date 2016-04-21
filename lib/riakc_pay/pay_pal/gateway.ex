defmodule RiakcPay.PayPal.Gateway do  

	alias RiakcPay.PayPal.Response
	alias RiakcPay.PayPal.Request
	alias RiakcPay.Gateway.PayPal.Authentication

	defp endpoint(mode) do
		if mode == "prod" do
			"https://api.paypal.com/v1/"
		else
			"https://api.sandbox.paypal.com/v1/";
		end
	end

	def site() do
		"https://www.paypal.com"
	end

	def purchase(app,config,charge,mode,notify) do
		purchase(app,config,charge,mode,notify,3)
	end

	def execute(app,config,charge,mode,params) do
		execute(app,config,charge,mode,params,3)
	end


	def cancel(app,config,charge,mode,params) do
		{:ok,true}
	end

	defp purchase(app,config,charge,mode,notify,0) do
		{:fail,:max_retries}
	end

	defp purchase(app,config,charge,mode,notify,time) do
		endpoint = endpoint(mode)
		client_id = config[mode]["client_id"]
		secret = config[mode]["secret"]
		app_id = app["id"]
		payment = Request.assemble_payment(app,charge,mode,notify)

		case purchase_payment(endpoint,app_id,client_id,secret,payment) do
			{:auth_error, _response} ->
				Authentication.clean_headers(app_id)
				purchase(app,config,charge,mode,notify,time - 1)
			{:nok, _reason} ->
				purchase(app,config,charge,mode,notify,time - 1)
			{:ok, response} ->
				purchase_response(response,charge,mode)
				
		end

	end

	
	defp purchase_payment(endpoint,app_id,client_id,secret,pay) do
		string_payment = Poison.encode!(pay)
		
		HTTPoison.post(endpoint <> "payments/payment", string_payment, 
			Authentication.headers(endpoint,app_id,client_id,secret),
			timeout: :infinity, recv_timeout: :infinity)
		|> Response.handle
	end


	defp purchase_response(response,charge,mode) do
		params = %{}
		
		links = response["links"]
		if nil == links do
			{:error,nil,%{}}
		else
			link = Enum.find(links, fn(link) -> 
				link["rel"] == "approval_url"
			end)
			{:ok,
				%{
					"channel" => "Paypal",
					"redirect" => true,
					"method" => "void",
					"endpoint" => link["href"],
					"params" => params
				},
				%{"invoice_no" => response["id"]}
			}
	
		end
	end

	defp execute(app,config,charge,mode,params,0) do
		{:fail,:max_retries}
	end

	defp execute(app,config,charge,mode,params,time) do
		endpoint = endpoint(mode)
		invoice_id = params["paymentId"]
		payer_id = params["PayerID"]

		client_id = config[mode]["client_id"]
		secret = config[mode]["secret"]
		
		app_id = app["id"]

		case execute_payment(endpoint,app_id,client_id,secret,invoice_id,payer_id) do
			{:auth_error, _response} ->
				Authentication.clean_headers(app_id)
				execute(app,config,charge,mode,params,time - 1)
			{:nok, _reason} ->
				execute(app,config,charge,mode,params,time - 1)
			{:ok, response} ->
				{r,data} = execute_response(response,charge,mode)
				data = Map.put(data,"payer_no",payer_id)
				{:ok,r,data}
		end

	end

	defp execute_payment(endpoint,app_id,client_id,secret,invoice_id,payer_id) do
		HTTPoison.post(endpoint <> "payments/payment/#{invoice_id}/execute", 
			Poison.encode!(%{payer_id: payer_id}),  
			Authentication.headers(endpoint,app_id,client_id,secret),
			timeout: :infinity, 
			recv_timeout: :infinity)
		|> Response.handle

	end

	defp execute_response(response,charge,mode) do
		payer_state = Response.payer_state(response)
		
		if payer_state == "approved" do
			payee_state = Response.payee_state(response)
			{true,%{"payer_state" => payer_state,"payee_state" => payee_state}}
		else
			{false,%{}}
		end
		
	end

end