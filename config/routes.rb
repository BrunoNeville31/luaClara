Rails.application.routes.draw do
  
  get '/woocommerce', to: 'produtos#woocommerce_list'
  get '/ideal', to:'produtos#ideal_soft_list'
  get '/sincronizar', to: 'home#sincronizar_sistema'

  root 'home#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
