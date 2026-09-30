# Configurar un Servidor Ubuntu para Selfhosting

**Compatibilidad:** Esta guía está pensada para realizar todo el proceso en **Ubuntu 24.04 LTS**. En otras versiones de Ubuntu o en otras distribuciones, los paquetes, nombres de servicios y algunos comandos pueden variar; verificá los pasos antes de aplicarlos.

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
```

### Actualizaciones automáticas de seguridad

Instalar el servicio si todavía no está instalado y revisar qué orígenes puede usar para las actualizaciones automáticas:

```bash
sudo apt install unattended-upgrades
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
```

Dentro de `Unattended-Upgrade::Allowed-Origins`, dejar activas estas entradas y comentar las demás, en especial `-updates`, `-proposed` y `-backports`:

```text
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
    // "${distro_id}:${distro_codename}-updates";
    // "${distro_id}:${distro_codename}-proposed";
    // "${distro_id}:${distro_codename}-backports";
};
```

La primera entrada es el origen base de la versión de Ubuntu; las otras habilitan seguridad y ESM si está disponible. Mantener comentadas las entradas de `-updates`, `-proposed` y `-backports` evita que se instalen automáticamente actualizaciones generales, propuestas o retroportadas.

Revisar también la configuración que programa la actualización diaria de las listas y la instalación desatendida:

```bash
sudo nano /etc/apt/apt.conf.d/20auto-upgrades
```

Debe incluir estas líneas:

```text
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
```

El valor `"1"` indica que ambas tareas se ejecutan a diario: la primera actualiza la información de paquetes disponibles y la segunda instala automáticamente las actualizaciones permitidas arriba. Esto ayuda a recibir correcciones de seguridad sin tener que iniciar cada actualización manualmente.

### Logrotate

Logrotate suele venir instalado por defecto en Ubuntu Server. Verificar que su temporizador esté activo y revisar la configuración general y las reglas por servicio:

```bash
systemctl status logrotate.timer                # Verifica el temporizador que ejecuta logrotate
cat /etc/logrotate.conf                         # Muestra la configuración general y los archivos incluidos
ls -lah /etc/logrotate.d/                       # Lista las reglas de rotación específicas de cada servicio
sudo logrotate -d /etc/logrotate.conf           # Simula la rotación y muestra qué haría, sin modificar archivos
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

**Nota:** En Ubuntu 26, `fastfetch` cumple la misma función que `neofetch`: mostrar información de hardware y software.

---

### 1.2 Crear usuarios separados para administración y aplicaciones

No se debe usar la cuenta `root` para trabajar normalmente. En su lugar, crear una cuenta administrativa personal (por ejemplo, `{admin}`) que pueda usar `sudo` para tareas del servidor. `{admin}` no es la cuenta root: `sudo` le permite elevar privilegios cuando hace falta.

```bash
sudo adduser {admin}                  # Crear la cuenta administrativa
sudo usermod -aG sudo {admin}         # Darle permisos administrativos mediante sudo
```

Antes de deshabilitar el acceso SSH de root, iniciar sesión por SSH como `{admin}` y comprobar que `sudo` funciona. Mantener abierta la sesión actual hasta confirmar el acceso nuevo.

Para cada aplicación, crear un usuario propio sin permisos de `sudo`. Por ejemplo, reemplazar `{software}` por el nombre de la aplicación (`mateflix`, `api`, etc.). Así cada servicio ejecutado por PM2 tiene su propia carpeta y sus archivos quedan aislados de los demás servicios.

```bash
sudo adduser {software}                                  # Crear el usuario sin privilegios administrativos
sudo mkdir -p /var/www/{software}                        # Crear su carpeta de trabajo
sudo chown -R {software}:{software} /var/www/{software} # Asignar la carpeta al usuario de la aplicación
sudo -iu {software}                                      # Cambiar a ese usuario para clonar e instalar la aplicación
```

Ejecutar Node, PM2 y la aplicación como `{software}`, nunca como `root`. Usar la cuenta `{admin}` y `sudo` para administrar el sistema; no agregar `{software}` al grupo `sudo`.

---

### 1.3. Configurar teclado

En algunos casos la configuración de distribución de teclado no es la correcta y dificulta el escribir caracteres especiales (símbolos)

```bash
sudo dpkg-reconfigure keyboard-configuration  # Ejecutar wizard de configuración
sudo service keyboard-setup restart           # Reiniciar servicio de teclado
```

---

## 2. Cambiar puerto default de SSH
**Importante:** Primero crear `{admin}` y comprobar que puede conectarse por SSH y ejecutar `sudo`. Antes de cerrar el puerto 22, permitir el nuevo puerto tanto en UFW como en el firewall del proveedor cloud, configurar ese mismo puerto en SSH, y probar una conexión nueva como `{admin}`. Mantener abierta la sesión actual hasta confirmar que la nueva conexión funciona.

```bash
sudo ufw allow 222/tcp            # Permitir el nuevo puerto antes de cambiar SSH
sudo nano /etc/ssh/sshd_config    # Configurar Port 222 y PermitRootLogin no
sudo sshd -t                      # Verificar la sintaxis antes de aplicar los cambios
sudo systemctl reload ssh         # Aplicar la configuración de SSH
# Desde otra terminal, probar: ssh -p 222 {admin}@IP_DEL_SERVIDOR
sudo ufw delete allow 22          # Solo después de confirmar el acceso por el puerto nuevo
sudo ufw deny 22/tcp              # Bloquear el puerto 22
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

NVM permite gestionar distintas versiones de Node.js. Ejecutar estos pasos como `{software}` y sin `sudo`: NVM instala Node.js para el usuario actual.

### 4.1 NVM (Node Version Manager)
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
source ~/.bashrc
```

### 4.2 Node.js
```bash
nvm install 26   # Instalar Node.js 26
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

**Este bloque instala MongoDB Community 8.0 en Ubuntu 24.04 LTS (Noble).**

```bash
sudo apt-get install -y gnupg curl  # Dependencias para agregar el repositorio
curl -fsSL https://pgp.mongodb.com/server-8.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
sudo apt-get update                 # Actualizar listado de repositorios
sudo apt-get install -y mongodb-org # Instalar MongoDB Community
mongod --version                    # Verificar versión
sudo systemctl start mongod         # Iniciar MongoDB
sudo systemctl enable mongod        # Habilitar MongoDB al arranque
```

**Nota:** A día de hoy (30-sept-2026), MongoDB no está oficialmente soportado en Ubuntu 26.

---

## 7. Redis

Redis usa por defecto el puerto `6379/tcp`. La instalación estándar queda disponible localmente; no abras ese puerto en UFW ni en el firewall cloud salvo que necesites conexiones remotas y hayas configurado autenticación y acceso de red restringido.

```bash
sudo apt install redis-server -y          # Instalar Redis
sudo systemctl start redis-server         # Iniciar el servicio
sudo systemctl enable redis-server        # Iniciar Redis automáticamente al arrancar Ubuntu
redis-cli ping                            # Verificar que responde: debe mostrar PONG
```

---

## 8. PM2

pm2 sirve para gestionar y mantener los proyectos node activos (corriendo) en el sistema

Ejecutar la instalación y los comandos de PM2 como `{software}`, sin `sudo`, para que PM2 administre la aplicación con ese usuario.

```bash
npm install pm2@latest -g         # Instalar PM2 globalmente para el usuario actual, sin sudo
pm2 --version                     # Verificar versión
pm2 startup systemd               # Configurar inicio al reiniciar; ejecutar el comando sudo que PM2 muestre
pm2 install pm2-logrotate         # Instala el módulo que rota los logs de aplicaciones administradas por PM2
pm2 conf pm2-logrotate            # Muestra la configuración actual del módulo
pm2 set pm2-logrotate:max_size 10M # Rota un log cuando supera 10 MB
pm2 set pm2-logrotate:retain 7     # Conserva hasta 7 logs rotados, además del log actual
pm2 set pm2-logrotate:compress true # Comprime los logs rotados
#
#
#comandos comunes de pm2
pm2 list                          # Lista procesos activos
pm2 start {src_index.js}          # Ejecuta un un proyecto Node
pm2 start {src_index} --name {name} # Ejecuta un proyecto y le asigna un nombre
pm2 start {src_index} --name {name} --max-memory-restart 512M # Comando que salva de leaks
pm2 save                          # Guarda configuración al reiniciar
pm2 {stop|restart|start} {name}   # Ejecuta un cambio de estado
pm2 monit                         # Monitorea aplicaciones
pm2 logs {name}                   # Ver logs 
pm2 logs {name} --err             # Ver logs de error
pm2 logs {name} --out             # Ver logs de salida (console.log)
```

## 9. Git

Controlador de versiones (de proyectos). Suele venir instalado en el SO

```bash
sudo apt install git    # Instalar Git
git --version           # Verificar versión
```

---

## 10. Nginx

Servidor HTTP que utilizamos como proxy reverso para exponer la aplicación node al exterior. También sirve como balanceador de carga

```bash
sudo apt install nginx   # Instalar Nginx
nginx -v                 # Verificar versión
```

---

## 11. Certbot (Let's Encrypt)

Genera certificados SSL para el dominio. No es estrictamente necesario si se utiliza cloudflare, ya que CF emite certificados

```bash
sudo apt install certbot python3-certbot-nginx  # Instalar Certbot
certbot --version                               # Verificar versión
```

---

## 12. UFW (Firewall)

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
sudo ufw {allow | deny} 222/tcp   # Permitir/bloquear SSH si ese es el puerto configurado
sudo ufw {allow | deny} 33        # Permitir/bloquea el puerto 33
#
#
#reglas comunes
sudo ufw allow 222/tcp # Permitir el puerto SSH configurado en el punto 2
sudo ufw allow http
sudo ufw allow https
sudo ufw default deny incoming #bloquea todo el trafico entrante
sudo ufw default allow outgoing #bloquea todo el trafico saliente
```

---

## 13. Fail2Ban

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
enabled = true    # Habilita protección para SSH
port = 222        # Puerto de SSH; cambiarlo si se usa otro (por ejemplo, 22)
backend = systemd # Lee los registros de sshd desde el journal de systemd
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
user: mateflix # Reemplaza {software} por este nombre
domain: mateflix.app
port: 3000
```


## 1. Clonar repositorio

En caso de ser un repositorio privado hay que generar un token desde github/settings y asignarle permisos al repositorio

```bash
cd /var/www/{software} # Entrar a la carpeta asignada a la aplicación
git clone <repo> .    # El punto clona aquí y evita crear /var/www/mateflix/mateflix

# Ejemplo público:
git clone https://github.com/usuario/repositorio.git .

# Para un repositorio privado, autentícate con tu token; este valor es ficticio y no es real:
git clone https://${TOKEN}:x-oauth-basic@${URL_REPO}.git .
```

## 2. Instalar dependencias y configurar entorno
```bash
cd /var/www/{software} # Entrar al directorio del proyecto como su usuario
npm i                 # instalamos dependencias
cp .env_example .env  # copiamos el archivo de de variables de entorno de ejemplo
nano .env             # Editar variables de entorno
```

## 3. Configurar PM2
```bash
pm2 start {main.js|server.js} --name mateflix --max-memory-restart 512M  # Iniciamos el proyecto
pm2 save                                       # Habilitamos el auto-inicio
```

**Backups:** Los procesos de backup se gestionan desde PM2 y envían las copias directamente a Cloudflare R2.

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
sudo certbot --nginx -d mateflix.app -d www.mateflix.app # Certificado para el dominio y www
sudo systemctl status certbot.timer  # Verificar el temporizador de renovación automática
sudo certbot renew --dry-run         # Comprobar que la renovación automática funciona
```

**Importante:** Es imprescindible mantener Certbot y su renovación funcionando para que el certificado del servidor no venza. En Cloudflare configurar el modo **Full (strict)**, no Flexible; el certificado de Certbot permite validar la conexión entre Cloudflare y el servidor.

---

## 5. Configurar Cloudflare
1. Configurar los **nameservers** hacia Cloudflare.
2. Agregar registros DNS:
    - Registro `A` para el dominio.
    - Registros `cname` para subdominio:
      - Nombre: `www`
      - Valor: `mateflix.app` #dominio ó dirección IP del servidor
      - TTL: Auto

3. Activar **SSL/TLS** en modo **Full (strict)**.
4. Configurar reglas de seguridad para proteger el servidor de accesos maliciosos.
5. Revisar Analytics y verificar tráfico hacia tu servidor.

---

**Servidor configurado y aplicación en funcionamiento.** 🚀
Guía escrita por Mathias Burgio

> **IMPORTANTE: ANTES DE DAR TODO POR TERMINADO, REINICIAR EL SERVIDOR (`sudo reboot`) Y COMPROBAR QUE ARRANCA CORRECTAMENTE Y QUE TODOS LOS SERVICIOS Y LA APLICACIÓN VUELVEN A FUNCIONAR.**

## Verificación final de servicios

Después del reinicio, revisar los servicios instalados y comprobar que están funcionando. `systemctl status` puede mostrar `active (exited)` para servicios que configuran algo y luego terminan; revisar también los detalles y mensajes de error que aparecen en la salida.

```bash
sudo systemctl status ssh                  # Verificar que SSH está activo y permite administrar el servidor
sudo systemctl status nginx                # Verificar el servidor web
sudo systemctl status ufw                  # Verificar el servicio del firewall
sudo ufw status numbered                   # Revisar el estado y las reglas/puertos habilitados en UFW
sudo systemctl status fail2ban              # Verificar la protección contra intentos de acceso
systemctl status logrotate.timer            # Verificar el temporizador de rotación de logs
sudo systemctl status certbot.timer         # Verificar la renovación automática de certificados
systemctl list-timers apt-daily.timer apt-daily-upgrade.timer # Revisar los temporizadores de actualizaciones automáticas
redis-cli ping                              # Si se instaló Redis; debe responder PONG
sudo systemctl status mongod                # Si se instaló MongoDB
sudo systemctl status mysql                 # Si se instaló MySQL
```

Para verificar PM2, cambiar a cada usuario de aplicación y ejecutar `pm2 status` por separado. Cada usuario solo ve los procesos PM2 que ejecuta con su propia cuenta:

```bash
sudo -iu {software}
pm2 status                                  # Repetir para cada usuario/aplicación
```
