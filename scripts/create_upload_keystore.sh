#!/usr/bin/env bash
set -euo pipefail
mkdir -p keystore
read -r -s -p "Keystore password: " STORE_PASS; echo
read -r -s -p "Key password: " KEY_PASS; echo
keytool -genkeypair -v \
  -keystore keystore/bmtgo-upload.jks \
  -storetype JKS \
  -alias bmtgo-upload \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$STORE_PASS" -keypass "$KEY_PASS" \
  -dname "CN=BMT GO, OU=Mobile, O=BMT GO, L=Astana, ST=Astana, C=KZ"
cat > android/key.properties <<EOP
storePassword=$STORE_PASS
keyPassword=$KEY_PASS
keyAlias=bmtgo-upload
storeFile=../keystore/bmtgo-upload.jks
EOP
chmod 600 android/key.properties keystore/bmtgo-upload.jks
echo "Upload keystore created. Back up both files securely."
