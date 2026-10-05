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

## 4. Node.js y npm

Para este servidor conviene partir de una **instalación limpia de Node.js a nivel del sistema**, de modo que Node.js y npm estén disponibles para todos los usuarios. Elegir esta opción o NVM según lo que necesiten las aplicaciones.

### 4.1 Instalación para todos los usuarios (recomendada)

Ejecutar una sola vez desde la cuenta `{admin}`:

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
node -v # Verificar Node.js
npm -v  # Verificar npm
```

**Nota:** El sufijo `_22.x` puede variar según la versión que se desee instalar; por ejemplo, `setup_24.x` instala Node.js 24. Elegir una versión compatible con la aplicación y disponible en [NodeSource](https://github.com/nodesource/distributions). Después, cada usuario puede ejecutar `node` y `npm` sin `sudo`.

### 4.2 Alternativa: NVM (Node Version Manager)

[NVM](https://github.com/nvm-sh/nvm) permite gestionar distintas versiones de Node.js, pero instala Node.js solo para el usuario actual. Es útil si las aplicaciones necesitan versiones diferentes. Ejecutar estos pasos como `{software}` y sin `sudo`, repitiéndolos para cada usuario que lo necesite:

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
source ~/.bashrc
```

### 4.3 Instalar Node.js con NVM
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

### 6.1 Replica set local de un solo nodo para transacciones

Para proyectos chicos que corren en una sola PC o servidor, usar **una única instancia de MongoDB** como replica set `rs0`. Las aplicaciones se conectan localmente con **usuario y contraseña**. Esta configuración habilita transacciones entre documentos, pero no ofrece redundancia si el servidor falla. [Referencia sobre transacciones](https://www.mongodb.com/docs/v8.0/core/transactions-production-consideration/).

Estos pasos parten de la instalación anterior, sin autenticación ni replica set configurados. Si ya hay datos, hacer un backup antes; el reinicio interrumpe las conexiones. Si ya existe un administrador de MongoDB, usar esa cuenta y omitir su creación.

**1. Crear primero el administrador de MongoDB.** Entrar desde el servidor:

```bash
mongosh
```

Dentro de `mongosh`:

```javascript
use admin
db.createUser({
  user: "mongo_admin",
  pwd: passwordPrompt(),
  roles: [{ role: "root", db: "admin" }]
})
exit
```

Elegir una contraseña larga y única cuando se solicite. `passwordPrompt()` evita escribirla en el historial. Esta cuenta administra MongoDB y no debe usarse en el proyecto.

**2. Preparar el archivo interno de MongoDB.**

**No se usan claves SSH para MongoDB.** El `keyFile` es un archivo interno que MongoDB requiere para combinar replica set y autenticación, incluso con un solo nodo. Se queda en esta PC; las aplicaciones no lo usan para iniciar sesión. [Referencia de autenticación del replica set](https://www.mongodb.com/docs/manual/tutorial/convert-standalone-to-replica-set/).

Desde la cuenta `{admin}` de Ubuntu, generar ese archivo una sola vez (si ya existe, conservarlo):

```bash
sudo apt install -y openssl
if ! sudo test -e /etc/mongodb-keyfile; then
  openssl rand -base64 756 | sudo tee /etc/mongodb-keyfile > /dev/null
fi
sudo chown mongodb:mongodb /etc/mongodb-keyfile
sudo chmod 400 /etc/mongodb-keyfile
```

**3. Activar autenticación y replica set.** Abrir la configuración desde la cuenta `{admin}` de Ubuntu:

```bash
sudo nano /etc/mongod.conf
```

Agregar o modificar estos bloques, sin duplicarlos ni borrar el resto de la configuración. Usar espacios para la indentación:

```yaml
net:
  port: 27017
  bindIp: localhost # Solo conexiones desde esta misma PC

replication:
  replSetName: rs0

security:
  authorization: enabled # Login con usuarios de MongoDB
  keyFile: /etc/mongodb-keyfile
```

Con `bindIp: localhost`, MongoDB acepta conexiones únicamente desde esta PC. No cambiarlo a `0.0.0.0` ni abrir el puerto `27017` en los firewalls. [Configuración oficial](https://www.mongodb.com/docs/v8.0/tutorial/deploy-replica-set-with-keyfile-access-control/).

**4. Reiniciar MongoDB:**

```bash
sudo systemctl restart mongod
sudo systemctl status mongod
```

**5. Ingresar con el administrador e inicializar el replica set.** La contraseña se pide en consola. `directConnection=true` permite conectarse al nodo antes de inicializarlo:

```bash
mongosh "mongodb://localhost:27017/admin?directConnection=true" --username mongo_admin --authenticationDatabase admin --password
```

Dentro de `mongosh`, ejecutar **una sola vez**:

```javascript
rs.initiate({
  _id: "rs0",
  members: [{ _id: 0, host: "localhost:27017" }]
})
```

Esperar unos segundos y ejecutar `db.hello().isWritablePrimary`. Continuar cuando devuelva `true` (el nodo ya es `PRIMARY`). Mantener abierta esta consola para crear el usuario de aplicación.

### 6.2 Crear el usuario de la aplicación

En la misma consola, autenticada como `mongo_admin`, comprobar el replica set y crear un usuario exclusivo para Mateflix:

```javascript
rs.status() // Debe mostrar el nodo como PRIMARY
db.getSiblingDB("mateflix").createUser({
  user: "mateflix_app",
  pwd: passwordPrompt(),
  roles: [{ role: "readWrite", db: "mateflix" }]
})
exit
```

Usar otra contraseña para `mateflix_app`. Este usuario puede leer y escribir solo en `mateflix`; repetir con nombres diferentes para cada proyecto. [Creación de usuarios y contraseñas](https://www.mongodb.com/docs/v8.0/tutorial/configure-scram-client-authentication/).

### 6.3 Cadena de conexión del proyecto

En el `.env` de la aplicación, usar la variable que lea el proyecto (por ejemplo, `MONGODB_URI`):

```dotenv
MONGODB_URI="mongodb://mateflix_app:CONTRASENA_CODIFICADA@localhost:27017/mateflix?authSource=mateflix&replicaSet=rs0"
```

- `mateflix_app`: usuario creado para la aplicación.
- `CONTRASENA_CODIFICADA`: reemplazar por su contraseña, codificando caracteres especiales para una URL; por ejemplo, `@` se escribe `%40` y `#` se escribe `%23`.
- `/mateflix`: base de datos que usa el proyecto.
- `authSource=mateflix`: base donde se creó el usuario, no `admin` en este ejemplo.
- `replicaSet=rs0`: debe coincidir con el nombre configurado en MongoDB.

Guardar el `.env` fuera de Git. La aplicación debe correr en esta misma PC, fuera de Docker: `localhost` apunta al MongoDB local y el login usa `mateflix_app` y su contraseña. No agregar el `keyFile` ni claves SSH al proyecto. [Formato de conexión](https://www.mongodb.com/docs/manual/reference/connection-string/) y [opciones de conexión](https://www.mongodb.com/docs/manual/reference/connection-string-options/).

Probar el acceso con el usuario de aplicación, sin escribir la contraseña en el comando:

```bash
mongosh "mongodb://localhost:27017/mateflix?authSource=mateflix&replicaSet=rs0" --username mateflix_app --password
```

Dentro de `mongosh`, ejecutar `db.runCommand({ ping: 1 })` (debe devolver `ok: 1`) y salir con `exit`. Si la aplicación ya estaba corriendo, reiniciarla como su usuario: `pm2 restart mateflix --update-env`. El proyecto debe cargar la nueva URI y usar sesiones/transacciones en su código; configurar el replica set no convierte automáticamente las operaciones en transacciones.

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

**Importante:** Con la instalación de Node.js para todos los usuarios, PM2 debe instalarse una sola vez desde el usuario administrativo `{admin}`, que tiene permisos de `sudo`. Así el comando `pm2` queda disponible también para los demás usuarios del servidor:

```bash
sudo npm install pm2@latest -g # Dejar el comando pm2 disponible para todos los usuarios
```

Si se eligió NVM, instalar PM2 como cada usuario `{software}`, sin `sudo`:

```bash
npm install pm2@latest -g # Instalar PM2 para el usuario actual
```

En ambos casos, ejecutar los siguientes comandos como `{software}`, sin `sudo`, para que PM2 administre la aplicación con ese usuario. El comando administrativo que muestre `pm2 startup` debe ejecutarse desde la cuenta `{admin}`.

**Rotación de logs:** `pm2-logrotate` debe instalarse con `pm2 install pm2-logrotate` en cada usuario de aplicación, sin `sudo`. El comando `sudo npm install -g pm2-logrotate` instala el paquete globalmente, pero no activa el módulo en el PM2 de los demás usuarios. [Instrucciones oficiales](https://github.com/keymetrics/pm2-logrotate#install).

```bash
pm2 --version                     # Verificar versión
pm2 startup systemd               # Configurar inicio al reiniciar; copiar el comando sudo para ejecutarlo como {admin}
pm2 install pm2-logrotate         # Repetir como cada usuario de aplicación, sin sudo
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

Para clonar un repositorio privado desde el servidor, configurar una **deploy key** de GitHub:

1. **Crear la clave SSH en el servidor, como el usuario de la aplicación.** Desde la cuenta `{admin}`, cambiar de usuario y luego generar la clave sin `sudo`:

   ```bash
   sudo -iu {software} # Por ejemplo: sudo -iu mateflix
   ssh-keygen -t ed25519
   ```

   Aceptar la ruta predeterminada (`~/.ssh/id_ed25519`) con Enter. Si ya existe una clave, no sobrescribirla. Podés protegerla con una contraseña (passphrase); Git la pedirá al usarla.

2. **Mostrar y copiar la clave pública completa:**

   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

   La salida se ve similar a este ejemplo ficticio:

   ```text
   ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB0123456789abcdefghijklmnopqrstuvwxyzABCDEF {usuario}@{servidor}
   ```

   Copiar toda la línea que muestra tu servidor, desde `ssh-ed25519` hasta `{usuario}@{servidor}`; no usar la clave del ejemplo.

   Copiar solo el archivo `.pub`. La clave privada (`id_ed25519`, sin `.pub`) queda en el servidor y no se comparte.

3. **En GitHub:** repositorio Mateflix → **Settings → Deploy keys → Add deploy key**. Poner un título identificable (por ejemplo, `servidor-mateflix`), pegar la clave pública en **Key** y guardar con **Add key**. Dejar **Allow write access** desmarcado si solo se necesita clonar y hacer `git pull`.

4. **Clonar en el servidor, con el mismo usuario que generó la clave:**

   ```bash
   cd /var/www/{software}
   git clone git@github.com:tuusuario/mateflix.git .
   ```

   Reemplazar `tuusuario` por el usuario u organización dueño del repositorio. El punto final clona en la carpeta actual, que debe estar vacía; sin el punto, crea una subcarpeta `mateflix`.

Repetir para cada usuario de aplicación y su repositorio: una deploy key da acceso a un solo repositorio y no se puede reutilizar en otros. [Referencia de GitHub](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys).

Para un repositorio público, también se puede clonar por HTTPS sin configurar una clave:

```bash
cd /var/www/{software}
git clone https://github.com/usuario/repositorio.git .
```

## 2. Instalar dependencias y configurar entorno
```bash
cd /var/www/{software} # Entrar al directorio del proyecto como su usuario
npm i                 # instalamos dependencias
cp .env_example .env  # copiamos el archivo de de variables de entorno de ejemplo
nano .env             # Editar variables de entorno
```

Si el proyecto usa MongoDB, configurar en `.env` la [cadena de conexión con usuario y replica set del punto 6.3](#63-cadena-de-conexión-del-proyecto).

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
