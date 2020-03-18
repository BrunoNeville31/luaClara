class HomeController < ApplicationController
  require 'net/sftp'
  def index
  end

    def sincronizar_sistema
      #Gerando Token de acesso
        resposta = RestClient.get("http://192.168.0.49:60000/auth/?serie=HIEAPA-605053-HJHL&codfilial=1")    
        response = JSON.parse(resposta.body)    
        token = "Token #{response["dados"]["token"]}"
        listar_pagina(token)
    end

    def listar_pagina(token)
     #Criando assinatura para listar as paginas
        time = Time.now.to_i.to_s
        key = "211609"
        metodo = "get"
        data = metodo + time
        signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), key, data)).strip()

          i = 1
          while i < 1000 do  
            paginas = RestClient.get("http://192.168.0.49:60000/produtos/#{i}", header={'Authorization': "#{token}", 'Signature': "#{signature}", 'CodFilial': '1', 'Timestamp': "#{time}"})        
            pagina = JSON.parse(paginas)
                if pagina["tipo"] == "FIM_DA_PAGINA"
                    break
                else
                    pagina["dados"].each do |produto|
                      # tenho todos os codigos liberados                      
                      cor = []
                      tamanho = []
                        if produto["tipo"] == 1
                              variacoes =  RestClient.get("http://192.168.0.49:60000/produtos/grades/#{produto["codigo"]}", header={'Authorization': "#{token}", 'Signature': "#{signature}", 'CodFilial': '1', 'Timestamp': "#{time}"})
                                variacoe = JSON.parse(variacoes)
                                  variacoe["dados"]["lista"].each do |variacao|
                                    cor.push(variacao["nomeTamanho"])
                                    tamanho.push(variacao["nomeCor"])
                                  end   
                        end # Fim do Tipo do Produto
                        a = 0
                        foto = []
                        while a < 100 do 
                          foto = RestClient.get("http://192.168.0.49:60000/fotos/#{produto["codigo"]}/#{a}", header={'Authorization': "#{token}", 'Signature': "#{signature}", 'CodFilial': '1', 'Timestamp': "#{time}"})
                          
                          if foto.size < 200
                            break
                          else                            
                            photo = Photo.new
                            photo.photo = "#{foto.body}"
                            photo.code_image = produto["codigo"]
                            photo.save!
                            Net::SFTP.start('192.169.82.86', 'upper@luaclara.ind.br', :password => 'Lua33775599Clar', :port => '21') do |sftp|	
	
                              sftp.upload!("#{foto.body}", "/home/luaclara/public_html/luaclara.ind.br/upper")
                              
                            end
                            a = a + 1                           
                          end
                        end # Fim do While de Fotos
                        nome = produto["nome"]
                        preco = produto["precos"][0]["preco"]
                        descricao_long = produto["observacao1"]
                        descricao_cur = produto["observacao2"]
                        estoque = produto["estoqueAtual"]
                        puts "#{nome}<--sai do while"
                        
                            @header = {
                              "User-Agent": "WooCommerce",
                              "Content-Type": "application/json;charset=utf-8",
                              "Accept": "application/json"
                                  }
        
                            @user_basic = {
                              username: "ck_962653bd56c3a93c91c5a6cf9a90aa7be5dba873", 
                              password: "cs_7a55edb9f321462cd5941de971d0268af72ffe0b"
                                      }

                            nomes = produto["nome"].gsub(/í/, "i").gsub(/ã/, "a").gsub(/á/, "a").gsub(/ç/, "c").gsub(/ó/, "o")
                            valido_produto = HTTParty.get("https://luaclara.ind.br/wp-json/wc/v3/products/?search=#{nomes}", :format=>:json, header: @header, basic_auth: @user_basic)
                                 
                            if valido_produto.present?
                              dados =  valido_produto[0]["id"]
                              atualiza_produto(nome, preco, descricao_long, descricao_cur, estoque, cor, tamanho, dados)
                            else
                              dados = []
                              cria_produto(nome, preco, descricao_long, descricao_cur, estoque, cor, tamanho, dados)
                            end #Fim do IF de valido_produto
                    end # Fim do each de cada produto
                end # Fim do if FIM_DA_PAGINA
          break
          i = i + 1 # Passa para proxima pagina
          end #Fim do while
          respond_to do |format|
            format.html{redirect_to root_path}
          end # Redirecionando para pagina principal
    end # Fim do def listar_pagina

    def atualiza_produto(nome, preco, descricao_long, descricao_cur, estoque, cor, tamanho, dados)
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
                  'name': "Rbuno",
                  "type": "simple",
                  "regular_price": "#{preco}",
                  "description": "#{descricao_long}",
                  "short_description": "#{descricao_cur}",
                  "stock_quantity": "#{estoque}",       
                  "images": [
                    {
                      "src": "http://demo.woothemes.com/woocommerce/wp-content/uploads/sites/56/2013/06/T_2_front.jpg"
                    },
                    {
                      "src": "http://demo.woothemes.com/woocommerce/wp-content/uploads/sites/56/2013/06/T_2_back.jpg"
                    }
                  ],                
                  "attributes": [
                    { "id": "1",
                      "name": "Cores",
                      "position": 0,
                      "visible": true,
                      "variation": true,
                      "options": cor
                    },
                    { "id": "2",
                      "name": "Tamanhos",
                      "position":0,
                      "visible": true,
                      "variation": true,
                      "options": tamanho
                    }
                  ]
                
                }.to_json
                @body = JSON.parse(data)
                woo = HTTParty.put("https://luaclara.ind.br/wp-json/wc/v3/products/#{dados}", :format=>:json, header: @header, basic_auth: @user_basic, body: @body)
    end # Fim do def atualizar

    def cria_produto(nome, preco, descricao_long, descricao_cur, estoque, cor, tamanho, dados)
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
                  "name": "BRuno",
                  "type": "simple",
                  "regular_price": "#{preco}",
                  "description": "#{descricao_long}",
                  "short_description": "#{descricao_cur}",
                  "stock_quantity": "#{estoque}",       
                  "images": [
                    {
                      "src": "http://demo.woothemes.com/woocommerce/wp-content/uploads/sites/56/2013/06/T_2_front.jpg"
                    },
                    {
                      "src": "http://demo.woothemes.com/woocommerce/wp-content/uploads/sites/56/2013/06/T_2_back.jpg"
                    }
                  ],                
                   "attributes": [
                    { "id": "1",
                      "name": "Cores",
                      "position":0,
                      "visible": true,
                      "variation": true,
                      "options": cor
                    },
                    { "id": "2",
                      "name": "Tamanhos",
                      "position":0,
                      "visible": true,
                      "variation": true,
                      "options": tamanho
                    }
                  ]              
                }.to_json
                @body = JSON.parse(data)
                woo = HTTParty.post("https://luaclara.ind.br/wp-json/wc/v3/products", :format=>:json, header: @header, basic_auth: @user_basic, body: @body)
                puts "#{woo}<-salvou?"
                puts "#{woo.al}<-salvou?"
    end # Fim do def de criar
    def foto_wordpress(produto)

    end
end