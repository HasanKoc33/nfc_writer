#!/usr/bin/env bash
# ─── FİRESOFT Deploy Script ─────────────────────────────────────────────────
# Usage: ./deploy.sh   (android/ klasöründen veya proje kökünden çalıştırılabilir)
# Requires: flutter, lftp (brew install lftp)
#
# Ne yapar:
#   1) Flutter release APK üretir (flutter build apk --release)
#   2) Aynı FTP sunucusuna bağlanıp public_html/firesoft_apss altındaki
#      eski apk'yı siler ve yenisini "firesoft_uts.apk" adıyla yükler
#      (üzerine yazma / ezme davranışı).
#
# NOT: Hedef klasör adı isteğe göre birebir "firesoft_apss" olarak
# ayarlandı — "firesoft_apps" olması gerekiyorsa REMOTE_DIR'i güncelle.

set -euo pipefail

# ─── Proje kökü ─────────────────────────────────────────────────────────────
# Bu script android/ altında yaşıyor; flutter komutları proje kökünden
# çalıştırılmalı.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ─── Config ───────────────────────────────────────────────────────────────
FTP_HOST="saruman.voligen.com"
FTP_USER="firesoftyaz"
FTP_PASS="9T5&yoUu*CC#Fr8r6Sc*ZmQjgsyBnzcMH4nSPF&8i&KNRPEvFK"

REMOTE_DIR="public_html/firesoft_apps"
REMOTE_FILENAME="nfc_writer.apk"

LOCAL_APK="$PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   FIRESOFT Deployment Script          ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ─── Step 1: Build Flutter release APK ─────────────────────────────────────
echo "▶ [1/2] Flutter release APK derleniyor..."
cd "$PROJECT_ROOT"
flutter build apk --release

if [ ! -f "$LOCAL_APK" ]; then
  echo "✗ APK bulunamadı: $LOCAL_APK"
  exit 1
fi
echo "  ✓ APK üretildi → $LOCAL_APK"

# ─── Step 2: Upload to server (eskisini silip üzerine yaz) ─────────────────
echo ""
echo "▶ [2/2] $REMOTE_DIR altına $REMOTE_FILENAME olarak yükleniyor..."

lftp -u "$FTP_USER","$FTP_PASS" -p 21 "$FTP_HOST" <<EOF
set ftp:passive-mode on
set ftp:ssl-allow no
mkdir -p $REMOTE_DIR
cd $REMOTE_DIR
set cmd:fail-exit no
rm -f $REMOTE_FILENAME
set cmd:fail-exit yes
put "$LOCAL_APK" -o $REMOTE_FILENAME
echo "APK uploaded."
bye
EOF

echo "  ✓ Yükleme tamamlandı"

# ─── Done ───────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  ✅ Deployment complete!                     ║"
echo "║  📦 $REMOTE_DIR/$REMOTE_FILENAME"
echo "╚══════════════════════════════════════════════╝"
echo ""
