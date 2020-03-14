
Caso o Computador desligue ou o Fechem a Tela do CMD ( por qualquer motivo) é necessário rodar esse comando:

1 Aperte a tecla Windows + r;

2 digite cmd;

3 o comando a cima irá abir uma tela preta para inserir comandos;

4 cole este comando: 				cd C:\Sites\luaclara\

5 em seguida cole este comando: 		set SSL_CERT_FILE=C:\RailsInstaller\cacert.pem

6 agora cole este ultimo comando: 		rails s

Obs.: Caso o resultado seja esse :
##############################################################################################################
		Puma starting in single mode...
		* Version 3.12.2 (ruby 2.6.5-p114), codename: Llamas in Pajamas
		* Min threads: 5, max threads: 5
		* Environment: development
		* Listening on tcp://localhost:3000
		Use Ctrl-C to stop
#############################################################################################################
 Isso significa que o servidor está rodando normalmente. Caso apresente algum erro chamar no número: (62) 3100-4291/(62) 9 8629-9727 = falar com Bruno



*** Não fechar a tela Preta, somente minimizar