#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
cd "$ROOT"

OUT="calendarprovider-a11-withapk-$(date +%Y%m%d).zip"
APP_DIR="system/priv-app/CalendarProvider"
TARGET_APK="$APP_DIR/com.android.providers.calendar.apk"
DEFAULT_DL="$APP_DIR/com.android.providers.calendar_11-30_minAPI30(nodpi)_apkmirror.com.apk"
PERM_XML="system/etc/permissions/privapp-permissions-com.android.providers.calendar.xml"

echo "==> Building BYO-APK zip from: $ROOT"
mkdir -p "$APP_DIR"

# 1) Find an APK to use
APK_CAND=""
if [ -f "$DEFAULT_DL" ]; then
  APK_CAND="$DEFAULT_DL"
elif ls "$APP_DIR"/*.apk >/dev/null 2>&1; then
  APK_CAND="$(ls "$APP_DIR"/*.apk | head -n 1)"
fi

if [ -z "${APK_CAND:-}" ]; then
  echo "ERROR: No APK found in $APP_DIR"
  echo "Place your APK here, e.g.:"
  echo "  $DEFAULT_DL"
  exit 1
fi

# 2) Normalize filename to canonical
if [ "$APK_CAND" != "$TARGET_APK" ]; then
  echo "-> Using APK: $(basename "$APK_CAND")"
  cp -f "$APK_CAND" "$TARGET_APK"
fi
echo "-> Canonical APK: $(basename "$TARGET_APK")"

# 3) Quick integrity check (requires 'unzip')
if command -v unzip >/dev/null 2>&1; then
  if ! unzip -t "$TARGET_APK" >/dev/null 2>&1; then
    echo "ERROR: APK failed ZIP integrity check: $TARGET_APK"
    exit 1
  fi
  if ! unzip -l "$TARGET_APK" | grep -q "AndroidManifest.xml"; then
    echo "ERROR: APK missing AndroidManifest.xml (invalid): $TARGET_APK"
    exit 1
  fi
else
  echo "!! Warning: 'unzip' not found; skipping APK integrity checks."
fi

# 3b) Warn if permissions XML missing
if [ ! -f "$PERM_XML" ]; then
  echo "!! Warning: $PERM_XML not found. Some ROMs require this allowlist for priv perms."
fi

# 4) Build the zip (exclude repo cruft)
find system -name '.DS_Store' -delete || true
echo "==> Creating $OUT"
zip -r9 "$OUT" \
  module.prop customize.sh system \
  -x ".git/*" -x ".github/*" -x "scripts/*" -x "*.zip" \
  -x ".DS_Store" -x "*/.DS_Store" -x "__MACOSX/*" \
  -x "README.md" -x "LICENSE" >/dev/null

echo "==> Done: $OUT"