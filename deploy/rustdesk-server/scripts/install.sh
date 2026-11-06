#!/bin/bash
# Instala o RafaDesk no Linux (Ubuntu, Debian, Mint e derivados, 64 bits).
# Uso:
#   curl -fsSL https://acesso.rafaelmarcolino.online/install.sh | sudo bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Rode com sudo: curl -fsSL https://acesso.rafaelmarcolino.online/install.sh | sudo bash" >&2
  exit 1
fi
if ! command -v apt-get >/dev/null 2>&1; then
  echo "Este instalador funciona em sistemas com apt (Ubuntu, Debian, Mint)." >&2
  exit 1
fi
if [ "$(uname -m)" != "x86_64" ]; then
  echo "Por enquanto o RafaDesk para Linux existe apenas para 64 bits (x86_64)." >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo "Baixando o RafaDesk..."
curl -fL --progress-bar -o "$TMP/rafadesk.deb" https://acesso.rafaelmarcolino.online/RafaDesk.deb
chmod 755 "$TMP"
chmod 644 "$TMP/rafadesk.deb"

echo "Instalando..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq "$TMP/rafadesk.deb"

for _ in $(seq 1 30); do
  systemctl is-active --quiet rafadesk 2>/dev/null && break
  sleep 2
done
sleep 3

echo
echo "RafaDesk instalado."
echo "ID: $(rafadesk --get-id 2>/dev/null || echo '(abra o RafaDesk para ver o ID)')"
