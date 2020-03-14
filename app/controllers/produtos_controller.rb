class ProdutosController < ApplicationController
  

  def woocommerce_list
  	@header = {
            "User-Agent": "WooCommerce",
            "Content-Type": "application/json;charset=utf-8",
            "Accept": "application/json"
          }

     @user_basic = {
            username: "ck_9b76eb4fda9dc852bc603dd874b02c420ae1a4ba", 
            password: "cs_271fc15f30cf5c285b7806441c4c3c6c1d064080"
          }
   
    @produtos = []
    paginas = []
    if @produtos.count == 0
	    i = 1
	    while i < 1000 do
	    	pagina = HTTParty.get("https://luaclara.ind.br/wp-json/wc/v3/products/?page=#{i}", header: @header, basic_auth: @user_basic).parsed_response
	    	if pagina.count == 0
	    		break
	    	else
	    		paginas.push(pagina)
	    		i = i + 1
	    	end    	
	    end
	    a = 1
	    while a < 100
	      if paginas[a].present?
		    paginas[a].each do |produto|
		    	@produtos.push(produto)
		    end
		  end
		    if paginas[a] == nil
		    	break
		    else
		    	a = a + 1
			end
		end
	end
	cookies[:woo] = @produtos.count
  end

  def ideal_soft_list

   	resposta = RestClient.get("http://192.168.0.49:60000/auth/?serie=HIEAPA-605053-HJHL&codfilial=1")
    response = JSON.parse(resposta.body)
    puts "#{response}<--response"
    puts "#{resposta.headers}<--headers"
  	token = "Token #{response["dados"]["token"]}"
  	listando_produtos(token)
  end

  def listando_produtos(token)

    time = Time.now.to_i.to_s
    key = "211609"
    metodo = "get"
    data = metodo + time
    signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), key, data)).strip()
  	
	shop = []
	  i = 1
	  while i < 100000 do		
		listar_produtos = RestClient.get("http://192.168.0.49:60000/produtos/detalhes/#{i}", header={'Authorization': "#{token}", 'Signature': "#{signature}", 'CodFilial': '1', 'Timestamp': "#{time}"})
		shop = i
		puts "#{listar_produtos}<--"
		puts "#{i}<--"
		if listar_produtos["dados"]["tipo"] == "REGISTRO_NAO_ENCONTRADO"
			break
		else
			i = i + 1		
		end
     end
  end
end
