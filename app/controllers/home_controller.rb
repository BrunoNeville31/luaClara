class HomeController < ApplicationController
  def index
  end

  def sincronizacao
  	## Gerando o Token do Cliente
    resposta = RestClient.get("http://192.168.0.49:60000/auth/?serie=HIEAPA-605053-HJHL&codfilial=1")
    response = JSON.parse(resposta.body)
    puts "#{response}<--response"
    puts "#{resposta.headers}<--headers"
  	token = "Token #{response["dados"]["token"]}"
  	
  	## Criando a Criptografia
  	time = Time.now.to_i.to_s
    key = "211609"
    metodo = "get"
    data = metodo + time
    signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), key, data)).strip()
  	
	shop = []
	  i = 1
	  while i < 1000 do		
		listar_produtos = RestClient.get("http://192.168.0.49:60000/produtos/#{i}", header={'Authorization': "#{token}", 'Signature': "#{signature}", 'CodFilial': '1', 'Timestamp': "#{time}"})
		produtos = JSON.parse(listar_produtos)
		produtos["dados"].each do |produto|
			puts "#{produto}<- produtos"
			variacao = []
			if produto["tipo"] == 1
				variacoes =  RestClient.get("http://192.168.0.49:60000/produtos/grades/#{produto["codigo"]}", header={'Authorization': "#{token}", 'Signature': "#{signature}", 'CodFilial': '1', 'Timestamp': "#{time}"})
				a = JSON.parse(variacoes)
				variacao.push({tamanho: a["dados"]["lista"][0]["nomeTamanho"], cor: a["dados"]["lista"][0]["nomeCor"]})
			end
			

			
			break
		end
		break
		i = i + 1
     end

    respond_to do |format|
    	format.html{redirect_to root_path}
    end
  end 
end
