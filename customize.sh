#!/system/bin/sh
# Magisk installer customization
# Ref: Magisk module docs (perms helpers: set_perm*, ui_print, abort)

# Inform user that script is starting
ui_print ">> Installing Calendar Provider (priv-app) for Android 11 (API 30)..."

# Variable setup for path constants
APP_DIR="$MODPATH/system/priv-app/CalendarProvider"
PERM_DIR="$MODPATH/system/etc/permissions"
TARGET_APK="$APP_DIR/com.android.providers.calendar.apk"
PERM_XML="$PERM_DIR/privapp-permissions-com.android.providers.calendar.xml"

# Ensure expected directories exist
mkdir -p "$APP_DIR" "$PERM_DIR"

# Confirm at least one APK present
FIRST_APK="$(ls "$APP_DIR"/*.apk 2>/dev/null | head -n 1)"
if [ -z "$FIRST_APK" ]; then
  abort "Missing APK: no .apk found in:
$APP_DIR
Place the Calendar Storage APK (Android 11) here, e.g.:
$APP_DIR/com.android.providers.calendar.apk"
fi

# Prefer a file starting with the package name; fall back to first .apk
PREF_APK="$(ls "$APP_DIR"/com.android.providers.calendar*.apk 2>/dev/null | head -n 1)"
[ -n "$PREF_APK" ] && FIRST_APK="$PREF_APK"

# Normalize to canonical filename
if [ "$FIRST_APK" != "$TARGET_APK" ]; then
  ui_print "Using APK: $(basename "$FIRST_APK")"
  mv -f "$FIRST_APK" "$TARGET_APK" || abort "Failed to move $(basename "$FIRST_APK") -> $(basename "$TARGET_APK")"
fi
ui_print "Canonical APK: $(basename "$TARGET_APK")"

# Safe APK integrity checks if 'unzip' exists
if command -v unzip >/dev/null 2>&1; then
  if ! unzip -t "$TARGET_APK" >/dev/null 2>&1; then
    abort "Error: $TARGET_APK failed ZIP integrity check."
  fi
  if ! unzip -l "$TARGET_APK" | grep -q "AndroidManifest.xml"; then
    abort "Error: $TARGET_APK missing AndroidManifest.xml (invalid APK)."
  fi
else
  ui_print "!! Warning: 'unzip' not available; skipping APK integrity checks."
fi

# SDK check (warn if not Android 11)
SDK="$(getprop ro.build.version.sdk 2>/dev/null)"
if [ "x$SDK" != "x30" ] && [ -n "$SDK" ]; then
  ui_print "!! Warning: Detected SDK=$SDK (expected 30 / Android 11). This module targets Android 11 only."
fi

# Warn if the privileged-permissions allowlist XML is missing
if [ ! -f "$PERM_XML" ]; then
  ui_print "!! Warning: $PERM_XML not found. Privileged permissions may not be granted on some ROMs."
fi

# Remove any user-installed duplicate to avoid conflicts
if command -v pm >/dev/null 2>&1; then
  ui_print "Checking for user-installed provider to avoid duplicates..."
  pm list packages | grep -q '^package:com\.android\.providers\.calendar$' && {
    ui_print "Found user-installed com.android.providers.calendar; attempting uninstall..."
    pm uninstall com.android.providers.calendar >/dev/null 2>&1 || true
  }
fi

# Set safe permissions (dirs 0755, files 0644)
ui_print "Setting permissions..."
set_perm_recursive "$MODPATH/system/priv-app" 0 0 0755 0644
set_perm_recursive "$MODPATH/system/etc/permissions" 0 0 0755 0644
chmod 0644 "$TARGET_APK" 2>/dev/null || true
[ -f "$PERM_XML" ] && chmod 0644 "$PERM_XML" 2>/dev/null || true

# Inform user device is ready to reboot
ui_print ">> Install complete. Reboot to activate."