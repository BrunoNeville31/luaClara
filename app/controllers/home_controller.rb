require 'net/ftp'
class HomeController < ApplicationController
  def index
  end
  def sincronizar_sistema
  #Gerando Token de acesso
    resposta = RestClient.get("http://192.168.0.49:60000/auth/?serie=HIEAPA-605053-HJHL&codfilial=1")    
    response = JSON.parse(resposta.body)    
    $token = "Token #{response["dados"]["token"]}"
    listar_pagina
    puts "#{$token}<--"
  end

  def listar_pagina
    #### Gerando Assinatura
    $time = Time.now.to_i.to_s
    $key = "211609"
    $metodo = "get"
    $data = $metodo + $time
    $signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), $key, $data)).strip()
    #### Assinatura para listar as paginas
        i =1 # Alterar 1 pelo numero da pagina
        while i < 1000 do 
            paginas = RestClient.get("http://192.168.0.49:60000/produtos/#{i}", header={'Authorization': "#{$token}", 'Signature': "#{$signature}", 'CodFilial': '1', 'Timestamp': "#{$time}"})        
            pagina = JSON.parse(paginas)
                if pagina["tipo"] == "FIM_DE_PAGINA"
                  break
                else
                  pagina["dados"].each do |produto|
                    if produto['codigoGrupo'] == 1
                      produto_ideal(produto) 
                    else
                      puts "grupo nao pertence"
                    end
                    
                  end # Fim do each de produto(individual)
                end # Fim do IF pagina["tipo"](pega todos os produtos da pagina)
          i = i + 1 # Acessa a proxima pagina.. Caso não seja FIM_DA_PAGINA
          puts " estamos na pagina #{i}"
        end # Fim do While(controle de Paginas da Ideal Soft)
        redirect_to root_path
  end
  def produto_ideal(produto)    
    nome_produto = produto["nome"]
    $preco_produto = []
    $estoque_produto = produto["estoqueAtual"]
    descricao_longa = produto["observacao1"]
    descricao_curta = produto["observacao2"]
    codigo_produto = produto["codigo"]
    categoria_produto = produto["codigoClasse"]
    $categoria_cadastrada = []
    $peso_produto = produto["pesoLiquido"]


    categorias = RestClient.get("http://192.168.0.49:60000/aux/classes", header={'Authorization': "#{$token}", 'Signature': "#{$signature}", 'CodFilial': '1', 'Timestamp': "#{$time}"})
    categoria = JSON.parse(categorias)

    categoria["dados"].each do |cat|
      if cat["codigo"].to_i == categoria_produto.to_i
        #$categoria_cadastrada.push({"id": cat["codigo"], "name": cat["nome"]})

        @header = {
              "User-Agent": "WooCommerce",
              "Content-Type": "application/json;charset=utf-8",
              "Accept": "application/json"
                  }

        @user_basic = {
              username: "ck_60614e44b5bd0eb8b1cf64501462c46aa3c21b04", 
              password: "cs_131a0015ed32c22466acdfe05ed0e7a381350cc0"
                      } 
      c = cat["nome"].gsub('Ã', 'A').gsub('ã', 'a').gsub('Õ', 'O').gsub('õ', 'o').gsub('Á', 'A').gsub('á', 'a')
      categories =  HTTParty.get("https://luaclarastore.com.br/wp-json/wc/v3/products/categories/?search=#{c}", :format=>:json, header: @header, basic_auth: @user_basic)
        if categories.size == 0
          data = {
            "name": "#{cat["nome"]}"
          }.to_json
          @body = JSON.parse(data)
          category = HTTParty.post("https://luaclarastore.com.br/wp-json/wc/v3/products/categories/", :format=>:json, header: @header, basic_auth: @user_basic, body: @body)
          puts "cadastrado categoria"
          a = JSON.parse(category.body)
          $categoria_cadastrada.push({"id": a["id"]})
        else
          $categoria_cadastrada.push({"id": categories.parsed_response[0]["id"]})
        end #  fim do IF de categoria
      end
    end # fim do each de categoria 
    
    precos = RestClient.get("http://192.168.0.49:60000/precos/#{codigo_produto}", header={'Authorization': "#{$token}", 'Signature': "#{$signature}", 'CodFilial': '1', 'Timestamp': "#{$time}"})        
  
    preco_tabela = JSON.parse(precos)
    preco_tabela["dados"]["precos"].each do |preco|
      if preco["tabela"] == "VENDA"
        $preco_produto.push(preco["preco"])
      else

      end # fim do each de Tabela de Veda
    end
    puts "preço do produto #{$preco_produto}"
    puts "categoria #{$categoria_cadastrada}"
    if produto["tipo"] == 1
      grade = true
      produto_foto(grade, nome_produto, descricao_longa, descricao_curta, codigo_produto)
    else
      grade = false
      produto_foto(grade, nome_produto, descricao_longa, descricao_curta, codigo_produto)
    end # fim do IF para verificação do Tipo
  end # metodo para gerar todos os dados para o cadastro do produto(Fará isso em todas as circunstancias) 
  def produto_foto(grade, nome_produto, descricao_longa, descricao_curta, codigo_produto)
    puts "colocando imagem do produto #{nome_produto}"
    a = 1
    imagens = []
    while a < 100 do
    pagina_foto = RestClient.get("http://192.168.0.49:60000/fotos/#{codigo_produto}/#{a}", header={'Authorization': "#{$token}", 'Signature': "#{$signature}", 'CodFilial': '1', 'Timestamp': "#{$time}"})
      if pagina_foto.size < 200
        break
      else
        puts "#{codigo_produto}_#{a}<-- inserindo essa imagem -->#{nome_produto}"        
        ### Criando um arquivo que irá ler as imagens   
          file = File.new("#{codigo_produto}#{a}.jpg", "wb")
          file.write("#{pagina_foto.body}")
          file.binmode
          file.close 
        ### Abrindo uma conexão com FTP do woocommerce
          host = "ftp.luaclarastore.com.br"
          login = "u838841540.luaClara_imagem"
          pass = "upperdev"
           Net::FTP.open(host, login, pass) do |ftp|
            ftp.login(user = login, passwd = pass)
            ftp.chdir('imagem')  
            ftp.put(file) 
           end # fim do bloco de armazenagem FTP
           captura = {src: "https://luaclarastore.com.br/imagem/imagem/#{codigo_produto}#{a}.jpg"}
           imagens.push(captura)          
      end # fim do IF para captura de imagens
      a = a + 1 #acessando o proximo produto
    end # fim do while para captura das fotos
    puts "passando dados para proximo (produto grade)"
    produto_grade(grade, nome_produto, descricao_longa, descricao_curta, codigo_produto, imagens)
  end # metodo para Salvar as Fotos no banco de imagens (Somente se o produto possuir imagens)
  def produto_grade(grade, nome_produto, descricao_longa, descricao_curta, codigo_produto, imagens)
    puts "verificando se é grade"
    if grade == true
      puts "Sou uma grade.. enviando dados para variação_woocommerce"
      variacao_woocommerce(grade, nome_produto, descricao_longa, descricao_curta, codigo_produto, imagens)
    else 
      cor =[]
      tamanho = [] 
      puts " não sou grade.. enviando dados para produto_criar"                      
      produto_criar(grade, nome_produto, descricao_longa, descricao_curta, codigo_produto, imagens, cor, tamanho)
    end # Fim do If verificação de grade      
  end # metodo para salvar grade (Somente se o produto for do Tipo GRADE)
  def variacao_woocommerce(grade, nome_produto, descricao_longa, descricao_curta, codigo_produto, imagens)
    puts "pegando as variações"
    tamanho = []
    cor = []
    variacoes_produto = RestClient.get("http://192.168.0.49:60000/produtos/grades/#{codigo_produto}", header={'Authorization': "#{$token}", 'Signature': "#{$signature}", 'CodFilial': '1', 'Timestamp': "#{$time}"})
    variacoes = JSON.parse(variacoes_produto)
    variacoes["dados"]["lista"].each do |variacao|
      tamanhos = variacao["nomeTamanho"]
      tamanho.push(tamanhos)
      cores = variacao["nomeCor"]
      cor.push(cores) 
    end # fim do bloco de variações
    puts "variações arquivadas.. enviando para criação de produtos"
    produto_criar(grade, nome_produto, descricao_longa, descricao_curta, codigo_produto, imagens, tamanho, cor)
  end # metodo para salvar as variações antes de salvar os produtos
  def produto_criar(grade, nome_produto, descricao_longa, descricao_curta, codigo_produto, imagens, tamanho, cor)
    puts "cadastrando o produto"
    @header = {
        "User-Agent": "WooCommerce",
        "Content-Type": "application/json;charset=utf-8",
        "Accept": "application/json"
            }

    @user_basic = {
        username: "ck_60614e44b5bd0eb8b1cf64501462c46aa3c21b04", 
        password: "cs_131a0015ed32c22466acdfe05ed0e7a381350cc0"
                }   
    #limpa_letras = nome_produto.gsub(/í/, "i").gsub(/ã/, "a").gsub(/á/, "a").gsub(/ç/, "c").gsub(/ó/, "o").gsub(/º/, "").gsub(/ª/, "").gsub("Ç", "c").gsub("Â", "a").gsub("Ô","o").delete("*")
    valido_produto = HTTParty.get("https://luaclarastore.com.br/wp-json/wc/v3/products/?sku=#{codigo_produto}", :format=>:json, header: @header, basic_auth: @user_basic)
      if valido_produto.present?        
        dados = valido_produto[0]["id"] 
        atualiza_produto(grade, nome_produto, descricao_longa, descricao_curta, codigo_produto, imagens, tamanho, cor, dados)
      else  
        tam = tamanho.uniq
        cors = cor.uniq
        puts "#{$estoque_produto.to_i}<- estoque"
          if grade == true
            tipo = "variable"
          else
            tipo = "simple"
          end # fim do IF de validação do tipo do produto

             product_save = { 
              "name": "#{nome_produto}",
                "type": "#{tipo}",
                "sku": "#{codigo_produto}",
                "regular_price": "#{$preco_produto}",
                "status": "publish",
                "catalog_visibility": "visible",
                "description": "#{descricao_longa}",
                "short_description": "#{descricao_curta}",
                "manage_stock": true,
                "stock_quantity": "#{$estoque_produto.to_i}",
                "stock_status": "instock", 
                "categories":$categoria_cadastrada,                         
                "images": imagens,
                "weight": "#{$peso_produto}",
                "dimensions": {
                "length": "5",
                "width": "10",
                "height": "15"
              },
              "attributes":[                
                {
                  "name": "Tamanho",
                  "position": 0,
                  "visible": true,
                  "variation": true,
                  "options": tam
                  }]                        
            }
            
            uri = URI('https://luaclarastore.com.br/wp-json/wc/v3/products/')
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
            req.basic_auth 'ck_60614e44b5bd0eb8b1cf64501462c46aa3c21b04', 'cs_131a0015ed32c22466acdfe05ed0e7a381350cc0'
            req.body = product_save.to_json
            res = http.request(req)
            puts "#{res.body}<--"
            puts "produto cadastrado"
            response = JSON.parse(res.body)
            
            if grade == true
              id_woo = response["id"] 
              variacao_produto(cor, tamanho, id_woo)
            end # fim do IF de grade(Criar metodo para criar variação)
    end # fim do IF de atualização
  end # metodo para criar o produto(Somente se o produto não existir)
  def variacao_produto(cor, tamanho, id_woo)
    
    tamanho.each do |tamanhos|    
      product_save = { 
                "regular_price": "#{$preco_produto}",  
                "stock_quantity": "#{$estoque_produto.to_i}",             
                "attributes": [
                  {   
                    "name": "Tamanho",             
                    "option": "#{tamanhos}"
                  }
                ]                       
              }              
              uri = URI("https://luaclarastore.com.br/wp-json/wc/v3/products/#{id_woo}/variations/")
              http = Net::HTTP.new(uri.host, uri.port)
              http.use_ssl = true
              req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
              req.basic_auth 'ck_60614e44b5bd0eb8b1cf64501462c46aa3c21b04', 'cs_131a0015ed32c22466acdfe05ed0e7a381350cc0'
              req.body = product_save.to_json
              res = http.request(req)            
              puts "Variação cadastrada"            
            end # fim do bloco each
  end
  def atualiza_produto(grade, nome_produto, descricao_longa, descricao_curta, codigo_produto, imagens, tamanho, cor, dados)
    puts "produto ja exite, vamos atualizar"
    puts "#{$preco_produto.first}"

    if grade == true
      tipo = "variable"
    else
      tipo = "simple"
    end # fim do IF de validação do tipo do produto
      product_save = { 
        "name": "#{nome_produto}",
          "type": "#{tipo}",         
          "price": "#{$preco_produto}",
          "status": "publish",
          "catalog_visibility": "visible",
          "description": "#{descricao_longa}",
          "short_description": "#{descricao_curta}",
          "manage_stock": true,
          "stock_quantity": "#{$estoque_produto.to_i}",         
          "stock_status": "instock",  
          "categories":$categoria_cadastrada,                         
          "images": imagens,        
          "weight": "#{$peso_produto}",
            "dimensions": {
              "length": "5",
              "width": "10",
              "height": "15"
            },
        "attributes":[          
          {
            "name": "Tamanho",
            "position": 0,
            "visible": true,
            "variation": true,
            "options": tamanho
            }]                        
      }
      
      uri = URI("https://luaclarastore.com.br/wp-json/wc/v3/products/#{dados}/")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      req = Net::HTTP::Put.new(uri.path, 'Content-Type' => 'application/json')
      req.basic_auth 'ck_60614e44b5bd0eb8b1cf64501462c46aa3c21b04', 'cs_131a0015ed32c22466acdfe05ed0e7a381350cc0'
      req.body = product_save.to_json
      res = http.request(req)
      puts "#{res.body}<--"
      puts "produto Atualizado"
    
  end

end
