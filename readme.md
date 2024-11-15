configurar un servidor ubuntu para selfhosting
nota 1: todo esto se podría simplificar con un panel de administración. Ej coolify
nota 2: se puede agregar una capa extra de seguridad utilizando docker y aislando la aplicacion del resto del sistema

1- Instalar ubuntu
    1.0- Instalar el sistema operativo del cloud/vpn. Utilizar el wizard del proveedor de hosting
    1.1- actualizar listado de paquetes
        sudo apt-get update
    1.2- actualizar paquetes instalados
        sudo apt-get upgrade
    1.3- instalamos neofetch (para ver info del sismtema)
        sudo apt install neofetch

    comando importantes
    hostname                        -> muestra el nombre de la pc/hostname
    hostname -i                     -> muestra la ip de la pc
    neofetch                        -> muestra informacion de hardware y software
    htop                            -> muestra actividad del sistema (ram, cpu)
    systemctl {comando} {servicio}  -> realiza una accion a un servicio. Ej. "systemctl start nginx", "systemctl enable mysql" 
 
2- Configurar teclado
    2.0- solo en caso de que el teclado de la consola (sistema operativo) sea distinto del teclado fisico
    2.1- ejecutar wizard de configuracion
        sudo dpkg-reconfigure keyboard-configuration
    2.2- reiniciar servicio de teclado
        sudo service keyboard-setup restart

3- cURL (client url)
    3.0- se utiliza para descargar archivos
    3.1- instalamos
        sudo apt install curl
    3.2- verificamos
        curl --version

4- node
    4.0- sirve para ejecutar node en el servidor
    4.1- instalamos nvm (node version manager) (se puede descargar otra que no sea la 0.39.4)
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash 
        source ~/.bashrc
    4.2- instalamos node y npm
        nvm install 20 #se puede cambiar a otra que no sea la 20
    4.3- verificamos
        node -v
        npm -v

5- mysql
    5.0- sistema gestor de base de datos
    5.1- instalamos
        sudo apt install mysql-server
    5.2- verificamos
        mysql -V (--version)
    5.3- agregamos seguridad (deshabilita opciones de inicios de sesion no necesarios)
        sudo mysql_secure_installation
    nota: el punto 5.3 puede traer problemas. Para iniciar sesion desde consola simplemente ejecutar "sudo mysql" ó "sudo mysql -u root -p". En caso de necesitar iniciar desde una aplicacion se debe crear un usuario y asignarle permisos para su correspondiente base de datos.

6- mongoDB
    6.0- sistema gestor de base de datos noSQL.
    NOTA: utilizar ubuntu 20.04 (o docker para instalar, ya que trae problemas al instalar en sistemas mas nuevos)
    NOTA: puede variar la clave GPG y version de mongoDB dependiendo la version de ubuntu que se este utilizando
    6.1- importamos la clave GPG para verificar autenticidad del los paquetes
        curl -fsSL https://pgp.mongodb.com/server-6.0.asc | sudo tee /etc/apt/trusted.gpg.d/mongodb-server-6.0.asc
    6.2- agregamos repositorio de mongoDB a la lista de repositorios locales (paquetes apt)
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    6.3- actualizamos la lista de paquetes disponibles (para que tome el recien agregado)
        sudo apt update
    6.4- instalamos
        sudo apt install -y mongodb-org
    6.5- verificamos servidor y mongo tools
        mongod --version
        sudo dpkg -l mongodb-database-tools
    6.6- iniciamos y habilitamos
        sudo systemctl start mongod
        sudo systemctl enable mongod

7- pm2
    7.0- administrador de proyectos node
    7.1- instalamos
        npm install pm2@latest -g
    7.2- verificamos
        pm2 --version
    7.3- comandos basicos
        pm2 list #muestra los procesos activos
        pm2 start {src_index.js} #inicia el archivo
        pm2 start {src_index} --name #inicia el proyecto y le asigna un nombre
        pm2 {status} {name} #{sopt | start | restart | delete} cambia el estado del proyecto
        pm2 save #guarda el estado para que si se reinica el servidor inice los proyectos automaticamente
        pm2 monit #controla el estado de las aplicaciones activas
        pm2 logs {name}

8- git
    8.0- controlador de versiones (de proyectos). Deberia estar instalado por defecto
    8.1- instalamos
        sudo apt install git
    8.2- verificamos
        git --version

9- nginx
    9.0- servidor http que utilizaremos como proxy reverso para exponer aplicacion node al exterior (tambien sirve como balanceador de carga)
    9.1- instalamos
        sudo apt install nginx
    9.2- verificamos
        nginx -v
        
10- certbot (lets Encrypt)
    10.0- agrega y gestiona SSL
    10.1- instalamos certbot
        sudo apt install certbot python3-certbot-nginx
    11.2- verificamos
        certbot --version

11- ufw (uncomplicated firewall)
    11.0- firewall
    11.1- instalamos
        sudo apt install ufw
    11.2- verificamos
        ufw --version
    11.3- comandos basicos
        sudo ufw app list #muestra aplicaciones permitidas
        sudo ufw status numbered #muestra las reglas del firewall, requiere que ufw este en enable
        sudo ufw {comando} #enable | disable | status
        sudo ufw {allow | deny} ssh #habilita o bloquea por aplicacion
        sudo ufw {allow | deny} 22 #habilita o bloquea por puerto
    11.4- habilitar reglas basicas
        sudo ufw allow ssh
        sudo ufw allow http
        sudo ufw allow https
        sudo ufw default deny incoming #bloquea todo el trafico excepto el previamente permitido
        sudo ufw default allow outgoing #bloquea todo el trafico excepto el previamente permitido

12- fail2ban
    12.0- proteje de ataques de fuerza bruta (generalmente para proteger SSH)
    12.1- instalamos
        sudo apt install fail2ban
    12.2- verficamos
        sudo systemctl status fail2ban
    12.2- configuramos reglas
        sudo vi /etc/fail2ban/jail.local #esto crea un archivo de configuracion
    12.3- pegamos la siguiente configuracio
    ```
        [DEFAULT]
        # Tiempo durante el cual se bloqueará una IP en segundos (600 = 10 minutos)
        bantime = 600

        # Número de intentos fallidos antes de bloquear la IP
        maxretry = 5

        # Tiempo de descubrimiento para contar los intentos fallidos en segundos (600 = 10 minutos)
        findtime = 600

        # Acción a tomar cuando se bloquea una IP (en este caso, usa UFW para bloquear la IP)
        banaction = ufw

        # Activar la protección de SSH
        [sshd]
        enabled = true
    ```
    12.4- iniciamos y habilitamos (en caso de tenerlo previamente iniciado hay que reiniciarlo)
        sudo systemctl start fail2ban
        sudo systemctl enable fail2ban


poner en funcionamiento
nombre: mateflix
dominio: mateflix.app
puerto: 3000

1- clonar repositorio
    1.1 creamos un token en github/settings. Solo le asignamos permisos de repo (**MEJORAR ESTA PARTE)
    1.2 en el servidor creamos una carpeta en la raiz que sea /www e ingresamos
        mkdir /www
        cd www
    1.3 clonamos el repositorio con el token
        git clone https://${TOKEN}:x-oauth-basic@${URL REPO}.git
2- instalar dependencias y configurar
    2.1 ingresamos a la carpeta del proyecto
        cd mateflix
    2.2 instalamos dependencias
        npm i
    2.3 copiamos el archivo .env_example por uno para produccion
        cp .env_example .env
    2.4 editamos las variables de entorno
        nano .env

3- configurar pm2
    3.1 en la carpeta del proyecto ejecutamos
        pm2 start {src_index} --name mateflix #src_index seria el nombre del archivo ejecutable. Ej main.js, index.js ó server.js
    3.2 guardamos configuracion para que ante reinicios de sistema se vuelvan a iniciar los proyectos
        pm2 save

4- configurar nginx.
    6.1 creamos un archivo por servidor 
        nano /etc/nginx/sites-available/mateflix.app
    6.2 agregamos el siguiente codigo
        server {
            listen 80;
            server_name mateflix.app www.mateflix.app;
            location / {
                proxy_pass http://localhost:3000; #cambiar por el puerto utilizado en node
                
                proxy_http_version 1.1; #para soportar web sockets
                proxy_set_header Upgrade $http_upgrade; #para soportar web sockets
                proxy_set_header Connection 'upgrade'; #para soportar web sockets
                proxy_set_header Host $host; #para cuando se trabajan con multiples host / servidores virtuales
                proxy_cache_bypass $http_upgrade; #para q las conexiones con websocket no trabajen sobre el cache
                
                client_max_body_size 50M; #tamaño maximo de datos
                
                # Ajustar los tiempos de espera para evitar timeouts
                proxy_read_timeout 90s;
                proxy_connect_timeout 90s;
                proxy_send_timeout 90s;
            }
        }
    6.3 verificamos que este todo correcto
        sudo nginx -t
    6.4 agregamos el enlace simbolico (nota: parametro 1 es la ruta absoluta del archivo, parametro 2 es la carpeta destino)
        sudo ln -s /etc/nginx/sites-available/mateflix.app /etc/nginx/sites-enabled/
    6.5 reiniciamos nginx
        sudo systemctl restart nginx
    6.5 generamos los certificados SSL
        sudo certbot --nginx -d mateflix.app

5- configurar cloudflare
    5.1 configurar los ns
        buscar los ns del proveedor de dominio y hacerlos paguntar a los provistos por cloudflare
    5.2 configurar los dns
        agregar los registros del proveedor de dominio en cloudflare
    5.3 agregar subdominios
        agregar un cname con los parametros name=www valor=mateflix.app 

 