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
      cor = []
      tamanho = []
			if produto["tipo"] == 1
				variacoes =  RestClient.get("http://192.168.0.49:60000/produtos/grades/#{produto["codigo"]}", header={'Authorization': "#{token}", 'Signature': "#{signature}", 'CodFilial': '1', 'Timestamp': "#{time}"})
        a = JSON.parse(variacoes)
        cor.push(a["dados"]["lista"][0]["nomeTamanho"])
        tamanho.push(a["dados"]["lista"][0]["nomeCor"])
      end
      
      @header = {
            "User-Agent": "WooCommerce",
            "Content-Type": "application/json;charset=utf-8",
            "Accept": "application/json"
                }

      @user_basic = {
            username: "ck_962653bd56c3a93c91c5a6cf9a90aa7be5dba873", 
            password: "cs_7a55edb9f321462cd5941de971d0268af72ffe0b"
                    }
      data = {
        'name': "#{produto["nome"]}",
        "type": "simple",
        "regular_price": "100,00",
        "description": "Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Vestibulum tortor quam, feugiat vitae, ultricies eget, tempor sit amet, ante. Donec eu libero sit amet quam egestas semper. Aenean ultricies mi vitae est. Mauris placerat eleifend leo.",
        "short_description": "Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas.",
        "categories": [
          {
            "id": "9"
          },
          {
            "id": "14"
          }
        ],
        "images": [
          {
            "src": "http://demo.woothemes.com/woocommerce/wp-content/uploads/sites/56/2013/06/T_2_front.jpg"
          },
          {
            "src": "http://demo.woothemes.com/woocommerce/wp-content/uploads/sites/56/2013/06/T_2_back.jpg",
          }
        ]
      }.to_json
      @body = JSON.parse(data)
      
      woo = HTTParty.post('https://luaclara.ind.br/wp-json/wc/v3/products/', :format=>:json, header: @header, basic_auth: @user_basic, body: @body)
			puts "#{woo}<-- cadastro do Produto no woocommerce"
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
