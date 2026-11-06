#!/usr/bin/env bash
# Instala e sobe o servidor RustDesk (hbbs + hbbr) numa VPS Ubuntu/Debian.
# Uso: sudo ./setup.sh
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Rode como root: sudo ./setup.sh" >&2
  exit 1
fi

cd "$(dirname "$0")"

if ! command -v docker >/dev/null 2>&1; then
  echo ">> Instalando Docker..."
  apt-get update -y
  apt-get install -y ca-certificates curl
  curl -fsSL https://get.docker.com | sh
fi

if ! docker compose version >/dev/null 2>&1; then
  echo ">> Instalando plugin docker compose..."
  apt-get install -y docker-compose-plugin
fi

if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
  echo ">> Liberando portas no UFW..."
  ufw allow 21115:21119/tcp
  ufw allow 21116/udp
fi

mkdir -p data
echo ">> Subindo hbbs e hbbr..."
docker compose pull
docker compose up -d

echo ">> Aguardando geracao da chave..."
for _ in $(seq 1 30); do
  [ -s data/id_ed25519.pub ] && break
  sleep 1
done

if [ ! -s data/id_ed25519.pub ]; then
  echo "Chave nao encontrada em data/id_ed25519.pub. Veja: docker compose logs hbbs" >&2
  exit 1
fi

IP="$(curl -fsS https://api.ipify.org || hostname -I | awk '{print $1}')"

cat <<EOF

=============================================
 Servidor RustDesk no ar
=============================================
 Servidor de ID : ${IP}
 Servidor relay : ${IP}
 Chave          : $(cat data/id_ed25519.pub)
=============================================
 Faca backup da pasta $(pwd)/data
 (id_ed25519 e a chave privada; se perder, todos
 os clientes precisam ser reconfigurados.)
EOF
