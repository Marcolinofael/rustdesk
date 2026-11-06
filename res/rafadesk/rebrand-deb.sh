#!/bin/bash
# Turns the stock rustdesk .deb into a rafadesk .deb.
# The app derives its service, process and desktop-file names from the app
# name in lowercase ("rafadesk"), so every installed path must use it too.
# Usage: rebrand-deb.sh <input.deb> <output.deb> <icon-256.png>
set -euo pipefail

IN="$1"
OUT="$2"
ICON="$3"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

dpkg-deb -R "$IN" "$WORK"
cd "$WORK"

mv usr/share/rustdesk usr/share/rafadesk
mv usr/share/rafadesk/rustdesk usr/share/rafadesk/rafadesk
rm -f usr/bin/rustdesk

mv usr/share/rafadesk/files/systemd/rustdesk.service usr/share/rafadesk/files/systemd/rafadesk.service
sed -i -e 's/RustDesk/RafaDesk/g' -e 's/rustdesk/rafadesk/g' usr/share/rafadesk/files/systemd/rafadesk.service

rm -f usr/share/icons/hicolor/256x256/apps/rustdesk.png usr/share/icons/hicolor/scalable/apps/rustdesk.svg
cp "$ICON" usr/share/icons/hicolor/256x256/apps/rafadesk.png

rm -f usr/share/applications/rustdesk.desktop usr/share/applications/rustdesk-link.desktop
cat > usr/share/applications/rafadesk.desktop <<'EOF'
[Desktop Entry]
Name=RafaDesk
GenericName=Suporte remoto
Comment=Suporte remoto - Rafa Consultoria em TI
Exec=rafadesk %u
Icon=rafadesk
Terminal=false
Type=Application
StartupNotify=true
Categories=Network;RemoteAccess;GTK;
Keywords=remote-control;remote-desktop;suporte;
StartupWMClass=rafadesk
EOF
cat > usr/share/applications/rafadesk-link.desktop <<'EOF'
[Desktop Entry]
Name=RafaDesk
NoDisplay=true
MimeType=x-scheme-handler/rafadesk;
TryExec=rafadesk
Exec=rafadesk %u
Icon=rafadesk
Terminal=false
Type=Application
StartupNotify=false
StartupWMClass=rafadesk
EOF

for f in DEBIAN/preinst DEBIAN/postinst DEBIAN/prerm DEBIAN/postrm; do
  [ -f "$f" ] && sed -i 's/rustdesk/rafadesk/g' "$f"
done
sed -i \
  -e 's/^Package: .*/Package: rafadesk/' \
  -e 's/^Maintainer: .*/Maintainer: Rafa Consultoria em TI <rafaelmarcolino.online>/' \
  -e 's|^Homepage: .*|Homepage: https://rafaelmarcolino.online|' \
  -e 's/^Description: .*/Description: RafaDesk - suporte remoto./' \
  DEBIAN/control

rm -f DEBIAN/md5sums
find . -type f ! -path './DEBIAN/*' -printf '%P\0' | xargs -0 md5sum > DEBIAN/md5sums

cd - >/dev/null
dpkg-deb --root-owner-group -b "$WORK" "$OUT"
