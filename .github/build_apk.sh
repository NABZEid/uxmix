#!/usr/bin/env bash
# Dipanggil oleh workflow. Aman dijalankan berulang (dipakai untuk versi Flutter cadangan).
set -euo pipefail

NAME="$(sed -n 's/^name:[[:space:]]*\([A-Za-z0-9_]*\).*/\1/p' pubspec.yaml | head -n1)"
NAME="${NAME:-uxmix}"

echo "== Flutter =="
flutter --version

echo "== Bersihkan sisa build sebelumnya =="
rm -rf android build .dart_tool pubspec.lock UxMix.apk

echo "== Buat folder android (lib, pubspec, assets tidak disentuh) =="
SCAFFOLD="$(mktemp -d)"
flutter create --no-pub --platforms=android --project-name "$NAME" --org com.uxmix "$SCAFFOLD/$NAME"
cp -r "$SCAFFOLD/$NAME/android" ./android

echo "== Atur AndroidManifest (izin internet + nama aplikasi) =="
python3 - <<'PY'
import re
p = 'android/app/src/main/AndroidManifest.xml'
t = open(p, encoding='utf-8').read()
if 'android.permission.INTERNET' not in t:
    t = re.sub(r'(<manifest[^>]*>)',
               r'\1\n    <uses-permission android:name="android.permission.INTERNET"/>',
               t, count=1)
t = re.sub(r'android:label="[^"]*"', 'android:label="UxMix"', t, count=1)
if 'usesCleartextTraffic' not in t:
    t = t.replace('<application', '<application android:usesCleartextTraffic="true"', 1)
open(p, 'w', encoding='utf-8').write(t)
print('Manifest OK')
PY
grep -q 'android.permission.INTERNET' android/app/src/main/AndroidManifest.xml

echo "== Ambil paket =="
flutter pub get

echo "== Icon aplikasi =="
if [ -f assets/icon.png ] && grep -q 'flutter_launcher_icons' pubspec.yaml; then
  cat > flutter_launcher_icons-ci.yaml <<'YAML'
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon.png"
YAML
  dart run flutter_launcher_icons -f flutter_launcher_icons-ci.yaml || echo "Icon dilewati (tidak fatal)"
else
  echo "Tidak ada assets/icon.png, pakai icon bawaan."
fi

echo "== Analisis kode (hanya informasi) =="
flutter analyze --no-fatal-infos --no-fatal-warnings || true

echo "== Build APK release =="
flutter build apk --release

cp build/app/outputs/flutter-apk/app-release.apk UxMix.apk
ls -lh UxMix.apk
