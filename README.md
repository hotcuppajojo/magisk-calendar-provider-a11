# Calendar Provider (Calendar Storage) — Magisk Module for Android 11 (API 30)

This Magisk module installs a **Calendar Provider** (`com.android.providers.calendar`) as a **privileged app** on **Android 11 / API 30** devices that ship without it enabled.  

It fixes **“Calendar storage is disabled”** errors and enables the standard provider authority:

`content://com.android.calendar`

so that calendar apps (Google Calendar, Etar, DAVx⁵, etc.) can read/write events.

- Tested on: Supernote Manta (A5 X2) running Chauvet 3.23.32  
- Should work on: Any Android 11 device missing `com.android.providers.calendar`

---

## Why a module?

On Android 8+, the Calendar Provider must be:
- a **privileged app** (`/system/priv-app`)  
- explicitly granted privileged permissions via an allowlist XML  

Magisk modules mount both systemlessly without modifying the real system partition.

---
## Releases

We provide **two flavors** of release zips:

### 1. BYO-APK (safe, redistributable)
- Does **not** contain the APK.  
- Build your own flashable zip **before installing**.
Steps:  
  1. Download the APK (Android 11 / API 30):  
     [`com.android.providers.calendar.apk` — Calendar Storage 11 (Android 11+)](https://www.apkmirror.com/apk/google-inc/calendar-storage-google/calendar-storage-google-11-release/calendar-storage-11-3-android-apk-download/)  
  2. Place it in the repo at:
     ```
     system/priv-app/CalendarProvider/com.android.providers.calendar.apk
     ```  
  3. Build the zip:
     * **macOS/Linux**  
       ```bash
       cd path/to/this/repo
       ./scripts/build-zip.sh
       ```  
       (Outputs something like `calendarprovider-a11-withapk-YYYYMMDD.zip`.)
     * **Windows (PowerShell)**  
       ```powershell
       Set-Location path\to\repo
       scripts\build-zip.ps1   # or just zip the folder root
       ```
This version is legally safe to share, since you supply the APK yourself.

### 2. `-withapk` (convenience, licensing caveat)
* The release zip already includes `com.android.providers.calendar.apk` and the permission allowlist.  
* ⚠️ **Licensing note:** Google’s Calendar Storage APK is proprietary. Redistribution may be subject to Google’s terms. Use at your own discretion.  
- If you prefer a fully open alternative, use the **AOSP/LineageOS CalendarProvider** for Android 11 (Apache 2.0) and package that APK with the BYO-APK method.

---

## Install (Magisk)

1. In **Magisk** → **Modules** → **Install from storage**, pick the zip.  
2. Reboot.  
That’s it—no extra pushing of files to the device.

---

## Verify provider is active

 ```bash
adb shell pm list packages -s | grep providers.calendar
adb shell pm enable com.android.providers.calendar
adb shell content query --uri content://com.android.calendar/calendars
 ```

* If the last command returns no error, the provider is alive.
* It’s fine if it shows 0 rows before any calendars/accounts sync.

---

## Sync options
* **DAVx⁵ (CalDAV)** — add your Google account via DAVx⁵ and enable Calendar sync.
* **Google Calendar Sync Adapter** — install `com.google.android.syncadapters.calendar` as another priv-app module (requires microG or Play login flow).

---

## Uninstall / Revert

Remove or disable the module in Magisk. It’s fully systemless.

---

## Notes
* Built for Android 11 / API 30 only.
* If you previously installed com.android.providers.calendar as a normal app, uninstall it before flashing this module.
* After OTA updates, you may need to re-flash Magisk itself; this module will then auto-mount again.

---

## Credits
* Android Calendar Provider (AOSP) docs and sources
* Magisk community for module templates and guidance
* APKMirror for hosting Calendar Storage 11 builds
* Tested on Supernote Manta (A5 X2, Chauvet 3.23.32) — shared with the r/Supernote community
