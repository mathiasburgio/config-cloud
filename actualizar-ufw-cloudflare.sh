#!/bin/bash
set -euo pipefail
export LC_ALL=C

[ "$(id -u)" -eq 0 ] || { echo "Ejecutar con sudo" >&2; exit 1; }
TMPDIR_CF=$(mktemp -d)
trap 'rm -rf -- "$TMPDIR_CF"' EXIT

# No cambiar SSH ni la política general. Si SSH comparte un puerto web,
# no es posible restringir ese puerto a Cloudflare sin afectar su acceso.
/usr/sbin/sshd -t
PUERTOS=$(/usr/sbin/sshd -T | awk '$1=="port" {print $2}')
[ -n "$PUERTOS" ] || { echo "No se detectó el puerto SSH" >&2; exit 1; }
for puerto in $PUERTOS; do
    case "$puerto" in
        80|443) echo "SSH usa el puerto $puerto; cancelado." >&2; exit 1 ;;
    esac
done

ufw status verbose > "$TMPDIR_CF/verbose"
grep -q '^Status: active$' "$TMPDIR_CF/verbose" || { echo "UFW no está activo" >&2; exit 1; }
grep -Eq '^Default: deny \(incoming\)(,|$)' "$TMPDIR_CF/verbose" || {
    echo "La política de entrada de UFW debe ser deny; configúrala manualmente." >&2; exit 1;
}
grep -Eq '^IPV6=yes([[:space:]]|$)' /etc/default/ufw || {
    echo "UFW debe tener IPv6 habilitado; revisar /etc/default/ufw." >&2; exit 1;
}

curl -fsS --max-time 20 https://www.cloudflare.com/ips-v4 > "$TMPDIR_CF/v4"
curl -fsS --max-time 20 https://www.cloudflare.com/ips-v6 > "$TMPDIR_CF/v6"
python3 - "$TMPDIR_CF" <<'PY'
import ipaddress, pathlib, sys
p = pathlib.Path(sys.argv[1])
networks = []
for name, version in (("v4", 4), ("v6", 6)):
    lines = (p / name).read_text().splitlines()
    if not lines:
        sys.exit(f"Lista {name} vacía")
    for line in lines:
        net = ipaddress.ip_network(line, strict=True)
        if net.version != version or net.prefixlen == 0:
            sys.exit(f"Red inesperada en {name}: {line}")
        networks.append(str(net))
if len(set(networks)) < 20:
    sys.exit("Lista de Cloudflare incompleta")
(p / "ips").write_text("\n".join(sorted(set(networks))) + "\n", newline="\n")
PY

# El análisis rechaza permisos generales, rangos o perfiles que puedan
# incluir puertos web: no intenta adivinar qué otras reglas se pueden borrar.
cat > "$TMPDIR_CF/revisar.py" <<'PY'
import ipaddress, json, pathlib, re, sys
mode, status_file, ips_file = sys.argv[1:]
allowed = set(pathlib.Path(ips_file).read_text().splitlines())
seen = set()
delete = set()
for line in pathlib.Path(status_file).read_text().splitlines():
    m = re.match(r'^\[\s*(\d+)\]\s+(.+)$', line)
    if not m:
        continue
    rule = re.fullmatch(r'(.+?)\s+(ALLOW|DENY|REJECT|LIMIT)\s+(IN|OUT|FWD)\s+(.+)', m[2].strip())
    if not rule:
        sys.exit('No se pudo interpretar una regla UFW: ' + line)
    dest, action, direction, source = rule.groups()
    if action != 'ALLOW' or direction != 'IN':
        continue
    dest = re.sub(r'\s+\(v6\)$', '', dest)
    # UFW alinea el comentario con espacios; quitarlos antes de validar la red.
    source = source.split('#', 1)[0].strip()
    source = re.sub(r'\s+\(v6\)$', '', source).strip()
    port = re.fullmatch(r'(\d+)(?:/(tcp|udp))?', dest, re.I)
    if not port:
        sys.exit('Regla de entrada no reconocida; revisarla manualmente: ' + line)
    number, proto = int(port[1]), (port[2] or '').lower()
    if number not in (80, 443):
        continue
    try:
        net = str(ipaddress.ip_network(source, strict=False))
    except ValueError:
        net = ''
    if proto == 'tcp' and net in allowed:
        seen.add((number, net))
    else:
        # Borrar por la regla exacta, nunca por un número que pueda cambiar.
        if source == 'Anywhere':
            args = (str(number) + ('/' + proto if proto else ''),)
        elif net:
            args = ('from', net, 'to', 'any', 'port', str(number))
            if proto:
                args += ('proto', proto)
        else:
            sys.exit('Origen no reconocido; no se elimina: ' + line)
        delete.add(args)
missing = {(port, net) for net in allowed for port in (80, 443)} - seen
if mode in ('check', 'verify') and missing:
    sys.exit(f'Verificación incompleta: faltan {len(missing)} reglas Cloudflare; no se eliminan permisos')
if mode == 'plan':
    print(json.dumps(sorted(delete)))
elif mode == 'verify':
    if delete:
        sys.exit(f'Verificación incompleta: {len(delete)} permisos ajenos')
PY

# Fallar antes de modificar nada si hay permisos que no podemos interpretar.
ufw status numbered > "$TMPDIR_CF/status"
python3 "$TMPDIR_CF/revisar.py" plan "$TMPDIR_CF/status" "$TMPDIR_CF/ips" > "$TMPDIR_CF/plan"

# Primero agregar las redes nuevas. Si algo falla, no se eliminan permisos.
while IFS= read -r ip; do
    ufw allow from "$ip" to any port 80 proto tcp comment 'Cloudflare'
    ufw allow from "$ip" to any port 443 proto tcp comment 'Cloudflare'
done < "$TMPDIR_CF/ips"

# Comprobar todas las redes antes de quitar permisos y borrar por regla exacta.
ufw status numbered > "$TMPDIR_CF/status"
python3 "$TMPDIR_CF/revisar.py" check "$TMPDIR_CF/status" "$TMPDIR_CF/ips"
python3 "$TMPDIR_CF/revisar.py" plan "$TMPDIR_CF/status" "$TMPDIR_CF/ips" > "$TMPDIR_CF/plan"
python3 - "$TMPDIR_CF/plan" <<'PY'
import json, subprocess, sys
with open(sys.argv[1]) as plan:
    for args in json.load(plan):
        subprocess.run(['ufw', '--force', 'delete', 'allow', *args], check=True)
PY

ufw status numbered > "$TMPDIR_CF/status"
python3 "$TMPDIR_CF/revisar.py" verify "$TMPDIR_CF/status" "$TMPDIR_CF/ips"
echo "Reglas web actualizadas. Revisar UFW y probar desde una red externa."
ufw status verbose
