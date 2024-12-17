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
curl -fsSL https://pgp.mongodb.com/server-6.0.asc | sudo tee /etc/apt/trusted.gpg.d/mongodb-server-6.0.asc
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt update
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
sudo apt install ufw          # Instalar UFW
sudo ufw allow ssh            # Permitir SSH
sudo ufw allow http           # Permitir HTTP
sudo ufw allow https          # Permitir HTTPS
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable               # Habilitar Firewall
```

---

## 12. Instalar Fail2Ban (Protección de fuerza bruta)
```bash
sudo apt install fail2ban
sudo vi /etc/fail2ban/jail.local
```

### Configuración:
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
sudo systemctl start fail2ban
sudo systemctl enable fail2ban
```

---

## 13. Cambiar puerto default de SSH
```bash
sudo nano /etc/ssh/sshd_config   # Editar configuración
sudo systemctl restart ssh       # Reiniciar servicio SSH
```

---