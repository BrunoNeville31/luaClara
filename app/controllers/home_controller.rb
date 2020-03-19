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
  end

  def listar_pagina
    #### Gerando Assinatura
    $time = Time.now.to_i.to_s
    $key = "211609"
    $metodo = "get"
    $data = $metodo + $time
    $signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), $key, $data)).strip()
    #### Assinatura para listar as paginas
        i = 1
        while i < 2 do 
            paginas = RestClient.get("http://192.168.0.49:60000/produtos/#{i}", header={'Authorization': "#{$token}", 'Signature': "#{$signature}", 'CodFilial': '1', 'Timestamp': "#{$time}"})        
            pagina = JSON.parse(paginas)
                if pagina["tipo"] == "FIM_DA_PAGINA"
                  break
                else
                  pagina["dados"].each do |produto|
                    produto_ideal(produto) 
                  end # Fim do each de produto(individual)
                end # Fim do IF pagina["tipo"](pega todos os produtos da pagina)
          i = i + 1 # Acessa a proxima pagina.. Caso não seja FIM_DA_PAGINA
        end # Fim do While(controle de Paginas da Ideal Soft)
        redirect_to root_path
  end
  def produto_ideal(produto)    
    nome_produto = produto["nome"]
    preco_produto = produto["precos"][0]["preco"]
    estoque_produto = produto["estoqueAtual"]
    descricao_longa = produto["observacao1"]
    descricao_curta = produto["observacao2"]
    codigo_produto = produto["codigo"]  
    if produto["tipo"] == 1
      grade = true
      produto_foto(grade, nome_produto, preco_produto, estoque_produto, descricao_longa, descricao_curta, codigo_produto)
    else
      grade = false
      produto_foto(grade, nome_produto, preco_produto, estoque_produto, descricao_longa, descricao_curta, codigo_produto)
    end # fim do IF para verificação do Tipo
  end # metodo para gerar todos os dados para o cadastro do produto(Fará isso em todas as circunstancias) 
  def produto_foto(grade, nome_produto, preco_produto, estoque_produto, descricao_longa, descricao_curta, codigo_produto)
    puts "colocando imagem"
    a = 1
    imagens = []
    while a < 100 do
    pagina_foto = RestClient.get("http://192.168.0.49:60000/fotos/#{codigo_produto}/#{a}", header={'Authorization': "#{$token}", 'Signature': "#{$signature}", 'CodFilial': '1', 'Timestamp': "#{$time}"})
      if pagina_foto.size < 200
        break
      else        
        ### Criando um arquivo que irá ler as imagens   
          file = File.new("#{codigo_produto}_#{a}.jpg", "wb")
          file.write("#{pagina_foto.body}")
          file.binmode
          file.close 
        ### Abrindo uma conexão com FTP do woocommerce
          host = "ftp.upperdesenvolvimento.com"
          login = "u131555075.brunon"
          pass = "brunoeisa3101"
           Net::FTP.open(host, login, pass) do |ftp|
            ftp.login(user = login, passwd = pass)
            ftp.chdir('testesBruno')  
            ftp.put(file) 
           end # fim do bloco de armazenagem FTP
           captura = {src: "http://upperdesenvolvimento.com/testesBruno/#{codigo_produto}_#{a}.jpg"}
           imagens.push(captura)
          a = a + 1 #acessando o proximo produto
      end # fim do IF para captura de imagens
    end # fim do while para captura das fotos
    puts "passando dados para proximo (produto grade)"
    produto_grade(grade, nome_produto, preco_produto, estoque_produto, descricao_longa, descricao_curta, codigo_produto, imagens)
  end # metodo para Salvar as Fotos no banco de imagens (Somente se o produto possuir imagens)
  def produto_grade(grade, nome_produto, preco_produto, estoque_produto, descricao_longa, descricao_curta, codigo_produto, imagens)
    puts "verificando se é grade"
    if grade == true
      puts "Sou uma grade.. enviando dados para variação_woocommerce"
      variacao_woocommerce(grade, nome_produto, preco_produto, estoque_produto, descricao_longa, descricao_curta, codigo_produto, imagens)
    else  
      puts " não sou grade.. enviando dados para produto_criar"                      
      produto_criar(grade, nome_produto, preco_produto, estoque_produto, descricao_longa, descricao_curta, codigo_produto, imagens)
    end # Fim do If verificação de grade      
  end # metodo para salvar grade (Somente se o produto for do Tipo GRADE)
  def variacao_woocommerce(grade, nome_produto, preco_produto, estoque_produto, descricao_longa, descricao_curta, codigo_produto, imagens)
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
    produto_criar(grade, nome_produto, preco_produto, estoque_produto, descricao_longa, descricao_curta, codigo_produto, imagens, tamanho, cor)
  end # metodo para salvar as variações antes de salvar os produtos
  def produto_criar(grade, nome_produto, preco_produto, estoque_produto, descricao_longa, descricao_curta, codigo_produto, imagens, tamanho, cor)
    puts "cadastrando o produto"
    @header = {
        "User-Agent": "WooCommerce",
        "Content-Type": "application/json;charset=utf-8",
        "Accept": "application/json"
            }

    @user_basic = {
        username: "ck_962653bd56c3a93c91c5a6cf9a90aa7be5dba873", 
        password: "cs_7a55edb9f321462cd5941de971d0268af72ffe0b"
                }   
    limpa_letras = nome_produto.gsub(/í/, "i").gsub(/ã/, "a").gsub(/á/, "a").gsub(/ç/, "c").gsub(/ó/, "o")
    valido_produto = HTTParty.get("https://luaclara.ind.br/wp-json/wc/v3/products/?search=#{limpa_letras}", :format=>:json, header: @header, basic_auth: @user_basic)
      if valido_produto.present? 
        atualiza_produto(grade, nome_produto, preco_produto, estoque_produto, descricao_longa, descricao_curta, codigo_produto, imagens, tamanho, cor)
      else  
          if grade == true
            tipo = "variable"
          else
            tipo = "simple"
          end # fim do IF de validação do tipo do produto
            product_save = { 
              "name": "#{nome_produto}",
                "type": "#{tipo}",
                "regular_price": "#{preco_produto}",
                "status": "publish",
                "catalog_visibility": "visible",
                "description": "#{descricao_longa}",
                "short_description": "#{descricao_curta}",
                "stock_status": "instock",                          
                "images": imagens,
              "attributes":[
                {
                "name": "Cor",
                "position": 0,
                "visible": true,
                "variation": true,
                "options": cor
                },
                {
                  "name": "Tamanho",
                  "position": 0,
                  "visible": true,
                  "variation": true,
                  "options": tamanho
                  }]                      	
            }
            
            uri = URI('https://luaclara.ind.br/wp-json/wc/v3/products/')
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
            req.basic_auth 'ck_962653bd56c3a93c91c5a6cf9a90aa7be5dba873', 'cs_7a55edb9f321462cd5941de971d0268af72ffe0b'
            req.body = product_save.to_json
            res = http.request(req)

            puts "#{res}<-- resposta"
            puts "#{res.a}"
    end # fim do IF de atualização
  end # metodo para criar o produto(Somente se o produto não existir)

  def atualiza_produto(grade, nome_produto, preco_produto, estoque_produto, descricao_longa, descricao_curta, codigo_produto, imagens, tamanho, cor)
    redirect_to root_path
  end

end