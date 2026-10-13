#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -f android/key.properties || -f android/vi-nho-release.jks ]]; then
  echo 'Đã có khóa/cấu hình ký; giữ lại để cập nhật APK đã cài.'
  exit 0
fi
KEYTOOL_BIN="${JAVA_HOME:+$JAVA_HOME/bin/}keytool"
if ! command -v "$KEYTOOL_BIN" >/dev/null; then
  echo 'Cần JDK 17+ và keytool trong PATH (hoặc đặt JAVA_HOME).'
  exit 1
fi
TASK_KEY_PASSWORD="$(od -An -N24 -tx1 /dev/urandom | tr -d ' \n')"
"$KEYTOOL_BIN" -genkeypair -v -keystore android/vi-nho-release.jks \
  -alias vi-nho -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$TASK_KEY_PASSWORD" -keypass "$TASK_KEY_PASSWORD" \
  -dname 'CN=Vi Nho Mini Project, OU=Student Project, O=VKU, L=Da Nang, C=VN'
cat > android/key.properties <<KEYS
storePassword=$TASK_KEY_PASSWORD
keyPassword=$TASK_KEY_PASSWORD
keyAlias=vi-nho
storeFile=vi-nho-release.jks
KEYS
chmod 600 android/key.properties android/vi-nho-release.jks
echo 'Đã tạo khóa ký release cục bộ. Không đưa hai file này lên GitHub.'
