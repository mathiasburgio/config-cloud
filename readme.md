# Configurar un Servidor Ubuntu para Selfhosting

**Nota 1:** Todo esto se podría simplificar con un panel de administración como [Coolify](https://coolify.io/).

**Nota 2:** Se puede agregar una capa extra de seguridad utilizando Docker y aislando la aplicación del resto del sistema.

---

## 1. Instalar Ubuntu

Ubuntu es el sistema operativo sobre el cual se ejecuta todo

### 1.0 Instalar el sistema operativo
Utilizar el wizard del proveedor de hosting (cloud/VPN) e ingresamos por SSH

### 1.1 Actualizar sistema y paquetes
```bash
sudo apt-get update           # Actualizar listado de paquetes
sudo apt-get upgrade          # Actualizar paquetes instalados
sudo apt install neofetch     # Instalar neofetch para ver información del sistema
```

### Comandos importantes
```bash
which {servicio}                # Muestra la ruta completa del ejecutable
hostname                        # Muestra el nombre del PC/hostname
hostname -I                     # Muestra la IP del PC
neofetch                        # Muestra información de hardware y software
htop                            # Muestra actividad del sistema (RAM, CPU)
systemctl {comando} {servicio}  # Acciones en un servicio (start, enable, etc.)
```

---

### 1.2 Crear un usuario y asignar permisos

Importante evitar ejecutar todo como root para mas seguridad

```bash
sudo adduser nodeuser               # Crear usuario
sudo groupadd www-group             # Crear grupo
sudo usermod -aG www-group nodeuser # Asignar usuario al grupo
sudo chgrp -R www-group /var/www    # Cambiar grupo del directorio
sudo chmod -R 775 /var/www          # Asignar permisos al grupo
sudo chmod g+s /var/www             # Permisos persistentes
su nodeuser                         # Iniciar sesión con el nuevo usuario
```

---

### 1.3. Configurar teclado

En algunos casos la configuración de distribución de teclado no es la correcta y dificulta el escribir caracteres especiales (símbolos)

```bash
sudo dpkg-reconfigure keyboard-configuration  # Ejecutar wizard de configuración
sudo service keyboard-setup restart           # Reiniciar servicio de teclado
```

---

## 2. Cambiar puerto default de SSH
**Nota:** Si se tiene un firewall asegurarse de habilitar el nuevo puerto y bloquear el 22

```bash
sudo nano /etc/ssh/sshd_config   # Editar configuración
sudo systemctl restart ssh       # Reiniciar servicio SSH
```

---

## 3. cURL

Sirve para descargar software desde la consola

```bash
sudo apt install curl    # Instalar cURL
curl --version           # Verificar instalación
```

---

## 4. nvm, node.js y npm

NVM permite gestionar distintas versiones de node

### 4.1 NVM (Node Version Manager)
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
source ~/.bashrc
```

### 4.2 Node.js
```bash
nvm install 20   # Puedes cambiar "20" por otra versión
node -v          # Verificar Node.js
npm -v           # Verificar npm
```

---

## 5. MySQL

Sistema gestor de base de datos Mysql

```bash
sudo apt install mysql-server          # Instalar MySQL
mysql -V                               # Verificar versión
sudo mysql_secure_installation         # Configurar seguridad
```

**Nota:** Para iniciar sesión desde consola: `sudo mysql` o `sudo mysql -u root -p`.

---

## 6. MongoDB

Sistema gestor de bases de datos mongo

**Requisitos:** Utilizar **Ubuntu 20.04** o Docker para evitar problemas, o utilizar otras scripts de instalación.

```bash
curl -fsSL https://pgp.mongodb.com/server-6.0.asc | sudo tee /etc/apt/trusted.gpg.d/mongodb-server-6.0.asc    #importamos la clave GPG para verificar autenticidad del los paquetes
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list                        #agregamos repositorio de mongoDB
sudo apt update                     # Actualizamos listado de repositorios
sudo apt install -y mongodb-org     # Instalamos mongo
mongod --version                    # Verificar servidor
sudo dpkg -l mongodb-database-tools # Verificar tools
sudo systemctl start mongod         # Iniciar MongoDB
sudo systemctl enable mongod        # Habilitar MongoDB al arranque
```

---

## 7. PM2

pm2 sirve para gestionar y mantener los proyectos node activos (corriendo) en el sistema

```bash
npm install pm2@latest -g         # Instalar PM2
pm2 --version                     # Verificar versión
#
#
#comandos comunes de pm2
pm2 list                          # Lista procesos activos
pm2 start {src_index.js}          # Ejecuta un un proyecto Node
pm2 start {src_index} --name {name} # Ejecuta un proyecto y le asigna un nombre
pm2 save                          # Guarda configuración al reiniciar
pm2 {stop|restart|start} {name}   # Ejecuta un cambio de estado
pm2 monit                         # Monitorea aplicaciones
pm2 logs {name}                   # Ver logs 
pm2 logs {name} --err             # Ver logs de error
pm2 logs {name} --out             # Ver logs de salida (console.log)
```

## 8. Git

Controlador de versiones (de proyectos). Suele venir instalado en el SO

```bash
sudo apt install git    # Instalar Git
git --version           # Verificar versión
```

---

## 9. Nginx

Servidor HTTP que utilizamos como proxy reverso para exponer la aplicación node al exterior. También sirve como balanceador de carga

```bash
sudo apt install nginx   # Instalar Nginx
nginx -v                 # Verificar versión
```

---

## 10. Certbot (Let's Encrypt)

Genera certificados SSL para el dominio. No es estrictamente necesario si se utiliza cloudflare, ya que CF emite certificados

```bash
sudo apt install certbot python3-certbot-nginx  # Instalar Certbot
certbot --version                               # Verificar versión
```

---

## 11. UFW (Firewall)

Firewall para bloquear/habilitar puertos de comunicación

```bash
sudo apt install ufw              # Instalar UFW
ufw --version                     # Verificamos
#
#
#comandos comunes de ufw
sudo ufw app list                 # Muestra aplicaciones permitidas/bloqueadas
sudo ufw {enable|disable|status}  # Cambia el estado del firewall
sudo ufw status numbered          # Muestra las reglas de firewall
sudo ufw {allow | deny} ssh       # Permitir/bloquea SSH
sudo ufw {allow | deny} 33        # Permitir/bloquea el puerto 33
#
#
#reglas comunes
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw default deny incoming #bloquea todo el trafico entrante
sudo ufw default allow outgoing #bloquea todo el trafico saliente
```

---

## 12. Fail2Ban

Proteje contra ataques de fuerza bruta

```bash
sudo apt install fail2ban        # Instalamos
sudo systemctl status fail2ban   # Verificamos instalación
```

### 12.1 Configuración:
```bash
sudo vi /etc/fail2ban/jail.local   # Editamos/creamos el archivo de configuración
```
Agregamos el siguiente código

```ini
[DEFAULT]
bantime = 300      #tiempo de baneo. 300 = 5 min
maxretry = 5       #cantidad de intentos fallidos
findtime = 300     #intervalo de descubrimiento de repitencias. 300 = 5 min
banaction = ufw    #accion a tomar (ufw = bloquea IP)

[sshd]
enabled = true    #habilita proteccion a ssh
```

### 12.2 Iniciamos el servicio:
```bash
sudo systemctl start fail2ban   # Iniciamos el servicio
sudo systemctl enable fail2ban  # Asignamos al inicio del sistema
```

---

# Poner en funcionamiento una aplicación
```
Para este ejemplo vamos a configurar
appName: mateflix
domain: mateflix.app
port: 3000
```


## 1. Clonar repositorio

En caso de ser un repositorio privado hay que generar un token desde github/settings y asignarle permisos al repositorio

```bash
cd /var/www #vamos al directorio donde se deberian almacenar los proyectos

# Clonamos el repositorio
git clone https://github.com/user/repo.git # Para repositorios publicos

# Reemplazar TOKEN y URL_REPO con tus valores
git clone https://${TOKEN}:x-oauth-basic@${URL_REPO}.git # Para repositorios privados
```

## 2. Instalar dependencias y configurar entorno
```bash
cd mateflix           # ingresamos al directorio
npm i                 # instalamos dependencias
cp .env_example .env  # copiamos el archivo de de variables de entorno de ejemplo
nano .env             # Editar variables de entorno
```

## 3. Configurar PM2
```bash
pm2 start {main.js|server.js} --name mateflix  # Iniciamos el proyecto
pm2 save                                       # Habilitamos el auto-inicio
```

## 4. Configurar Nginx
```bash
cd /etc/nginx/sites-available                       # Nos movemos a la carpeta de gestion de sitios de nginx
sudo nano mateflix.app                              # Nombre del archivo = dominio
#sudo nano /etc/nginx/sites-available/mateflix.app  #igual que lo anterior
```

**Contenido:**
```nginx
server {
    listen 80;
    server_name mateflix.app www.mateflix.app; #dominio y subdominios
    location / {
        proxy_pass http://localhost:3000;        # Puerto local aquí
        proxy_http_version 1.1;                  # Para web sockets
        proxy_set_header Upgrade $http_upgrade;  # Para web sockets
        proxy_set_header Connection 'upgrade';   # Para web sockets
        proxy_set_header Host $host;             # Para cuando se trabajan con multiples host / servidores virtuales
        proxy_cache_bypass $http_upgrade;        # Para q las conexiones con websocket no trabajen sobre el cache
        client_max_body_size 50M;                # Tamaño máximo de datos

        # Ajustar los tiempos de espera para evitar timeouts
        proxy_read_timeout 90s;
        proxy_connect_timeout 90s;
        proxy_send_timeout 90s;
    }
}
```

### 4.1 Terminamos de configurar Nginx
```bash
sudo ln -s /etc/nginx/sites-available/mateflix.app /etc/nginx/sites-enabled/  # Creamos el enlace simbólico (acceso directo)
sudo nginx -t                        # Verificar configuración
sudo systemctl restart nginx         # Reiniciamos nginx
sudo certbot --nginx -d mateflix.app # Generamos los certificados (no es estrictamente necesario si trabajamos con cloudflare ya que dicho servicio los provee)
```

---

## 5. Configurar Cloudflare
1. Configurar los **nameservers** hacia Cloudflare.
2. Agregar registros DNS:
    - Registro `A` para el dominio.
    - Registros `cname` para subdominio:
      - Nombre: `www`
      - Valor: `mateflix.app` #dominio ó dirección IP del servidor
      - TTL: Auto

3. Activar **SSL/TLS** en modo "Flexible" o "Full".
4. Configurar reglas de seguridad para proteger el servidor de accesos maliciosos.
5. Revisar Analytics y verificar tráfico hacia tu servidor.

---

**Servidor configurado y aplicación en funcionamiento.** 🚀
