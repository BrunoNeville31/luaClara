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
  end

  def ideal_soft_list
  end
end
