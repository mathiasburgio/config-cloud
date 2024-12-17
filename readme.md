# Configurar un Servidor Ubuntu para Selfhosting

**Nota 1:** Todo esto se podría simplificar con un panel de administración como [Coolify](https://coolify.io/).

**Nota 2:** Se puede agregar una capa extra de seguridad utilizando Docker y aislando la aplicación del resto del sistema.

---

## 1. Instalar Ubuntu

### 1.0 Instalar el sistema operativo
- Utilizar el wizard del proveedor de hosting (cloud/VPN).

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

## 1.B Crear un usuario y asignar permisos
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

## 2. Configurar teclado
```bash
sudo dpkg-reconfigure keyboard-configuration  # Ejecutar wizard de configuración
sudo service keyboard-setup restart           # Reiniciar servicio de teclado
```

---

## 3. Instalar cURL
```bash
sudo apt install curl    # Instalar cURL
curl --version           # Verificar instalación
```

---

## 4. Instalar Node.js y npm

### 4.1 Instalar NVM (Node Version Manager)
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
source ~/.bashrc
```

### 4.2 Instalar Node.js
```bash
nvm install 20   # Puedes cambiar "20" por otra versión
node -v          # Verificar Node.js
npm -v           # Verificar npm
```

---

## 5. Instalar MySQL
```bash
sudo apt install mysql-server          # Instalar MySQL
mysql -V                               # Verificar versión
sudo mysql_secure_installation         # Configurar seguridad
```

**Nota:** Para iniciar sesión desde consola: `sudo mysql` o `sudo mysql -u root -p`.

---

## 6. Instalar MongoDB

**Requisitos:** Utilizar **Ubuntu 20.04** o Docker para evitar problemas.

### 6.1 Agregar clave GPG y repositorio
```bash
curl -fsSL https://pgp.mongodb.com/server-6.0.asc | sudo tee /etc/apt/trusted.gpg.d/mongodb-server-6.0.asc    #importamos la clave GPG para verificar autenticidad del los paquetes
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list                        #agregamos repositorio de mongoDB
sudo apt update             #actualizamos listado de repositorios
```

### 6.2 Instalar MongoDB
```bash
sudo apt install -y mongodb-org
mongod --version                    # Verificar servidor
sudo dpkg -l mongodb-database-tools # Verificar tools
sudo systemctl start mongod         # Iniciar MongoDB
sudo systemctl enable mongod        # Habilitar MongoDB al arranque
```

---

## 7. Instalar PM2

### 7.1 Instalar PM2 globalmente
```bash
npm install pm2@latest -g  # Instalar PM2
pm2 --version             # Verificar versión
```

### 7.2 Comandos básicos
```bash
pm2 list                          # Lista procesos activos
pm2 start {src_index.js}          # Inicia un archivo Node
pm2 start {src_index} --name NAME # Inicia proyecto con nombre
pm2 save                          # Guarda configuración al reiniciar sistema
pm2 monit                         # Monitorea aplicaciones
pm2 logs {name}                   # Ver logs
```

---

## 8. Instalar Git
```bash
sudo apt install git    # Instalar Git
git --version           # Verificar versión
```

---

## 9. Instalar Nginx (Proxy Reverso)
```bash
sudo apt install nginx   # Instalar Nginx
nginx -v                 # Verificar versión
```

---

## 10. Instalar Certbot (Let's Encrypt)
```bash
sudo apt install certbot python3-certbot-nginx  # Instalar Certbot
certbot --version                              # Verificar versión
```

---

## 11. Configurar UFW (Firewall)
```bash
sudo apt install ufw              # Instalar UFW
sudo ufw allow ssh                # Permitir SSH
sudo ufw allow http               # Permitir HTTP
sudo ufw allow https              # Permitir HTTPS
sudo ufw default deny incoming    # Bloqurea todo el trafico de ingreso (exepto los premitidos previamente)
sudo ufw default allow outgoing
sudo ufw enable                   # Habilitar Firewall
```

---

## 12. Instalar Fail2Ban (Protección contra fuerza bruta)
```bash
sudo apt install fail2ban        #instalamos
sudo systemctl status fail2ban   #verificamos instalacion

```

### Configuración:
```bash
sudo vi /etc/fail2ban/jail.local   #editamos/creamos el archivo de configuracion
```
Agregamos el siguiente código

```ini
[DEFAULT]
bantime = 600
maxretry = 5
findtime = 600
banaction = ufw

[sshd]
enabled = true
```

```bash
sudo systemctl start fail2ban   #iniciamos el servicio
sudo systemctl enable fail2ban  #lo asignamos al inicio del sistema
```

---

## 13. Cambiar puerto default de SSH
**Nota:** ufw deberia actualizarse solo en cuanto a la nueva configuración del puerto`.

```bash
sudo nano /etc/ssh/sshd_config   # Editar configuración
sudo systemctl restart ssh       # Reiniciar servicio SSH
```

---

## Poner en funcionamiento una aplicación (Mateflix)

### 1. Clonar repositorio
```bash
mkdir /www && cd /www
# Reemplazar TOKEN y URL_REPO con tus valores
git clone https://${TOKEN}:x-oauth-basic@${URL_REPO}.git
```

### 2. Instalar dependencias y configurar entorno
```bash
cd mateflix
npm i
cp .env_example .env
nano .env   # Editar variables
```

### 3. Configurar PM2
```bash
pm2 start {src_index} --name mateflix
pm2 save
```

### 4. Configurar Nginx
```bash
sudo nano /etc/nginx/sites-available/mateflix.app
```

**Contenido:**
```nginx
server {
    listen 80;
    server_name mateflix.app www.mateflix.app;
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        client_max_body_size 50M;
        proxy_read_timeout 90s;
        proxy_connect_timeout 90s;
        proxy_send_timeout 90s;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/mateflix.app /etc/nginx/sites-enabled/
sudo nginx -t            # Verificar configuración
sudo systemctl restart nginx
sudo certbot --nginx -d mateflix.app
```

---

## 5. Configurar Cloudflare
1. Configurar los **nameservers** hacia Cloudflare.
2. Agregar registros DNS:
    - Registro `A` para el dominio.
    - Subdominio:
      - Nombre: `www`
      - Valor: Dirección IP de tu servidor
      - TTL: Auto

3. Activar **SSL/TLS** en modo "Flexible" o "Full".
4. Configurar reglas de seguridad para proteger el servidor de accesos maliciosos.
5. Revisar Analytics y verificar tráfico hacia tu servidor.

---

**Servidor configurado y aplicación en funcionamiento.** 🚀
