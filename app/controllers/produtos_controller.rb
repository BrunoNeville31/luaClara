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
  	@a = Photo.first
   	resposta = RestClient.get("http://192.168.0.49:60000/auth/?serie=HIEAPA-605053-HJHL&codfilial=1")
    response = JSON.parse(resposta.body)
    puts "#{response}<--response"
    puts "#{resposta.headers}<--headers"
  	token = "Token #{response["dados"]["token"]}"
  	listando_produtos(token)
  end

  def listando_produtos(token)
  	@data = Photo.last.photo
  	
	puts "#{@data}"

    time = Time.now.to_i.to_s
    key = "211609"
    metodo = "get"
    data = metodo + time
    signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), key, data)).strip()
  	
	shop = []
	  i = 1
	  while i < 450 do		
		listar_produtos = RestClient.get("http://192.168.0.49:60000/fotos/8575/0", header={'Authorization': "#{token}", 'Signature': "#{signature}", 'CodFilial': '1', 'Timestamp': "#{time}"})
		@teste = listar_produtos
		puts "#{listar_produtos.body}<--"
		
		puts "#{listar_produtos.methods}<-- fotos"
		foto = Photo.new
		foto.photo = listar_produtos
		foto.save!		
			
		break
		
     end
  end
end
