# Build BYO-APK Magisk zip (Windows PowerShell)
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Resolve-Path (Join-Path $ScriptDir "..")
Set-Location $Root

$Out = "calendarprovider-a11-withapk-$((Get-Date).ToString('yyyyMMdd')).zip"
$AppDir = "system/priv-app/CalendarProvider"
$TargetApk = Join-Path $AppDir "com.android.providers.calendar.apk"
$DefaultDl = Join-Path $AppDir "com.android.providers.calendar_11-30_minAPI30(nodpi)_apkmirror.com.apk"
$PermXml = "system/etc/permissions/privapp-permissions-com.android.providers.calendar.xml"

Write-Host "==> Building BYO-APK zip from: $Root"

# Ensure directory exists
New-Item -Force -ItemType Directory -Path $AppDir | Out-Null

# 1) Find an APK to use
$apkCand = $null
if (Test-Path $DefaultDl) {
  $apkCand = $DefaultDl
} else {
  $candidates = Get-ChildItem -Path $AppDir -Filter *.apk -ErrorAction SilentlyContinue
  if ($candidates) { $apkCand = $candidates[0].FullName }
}

if (-not $apkCand) {
  throw "No APK found in $AppDir. Place your APK here, e.g.:`n  $DefaultDl"
}

# 2) Normalize filename to canonical
if ($apkCand -ne $TargetApk) {
  Write-Host "-> Using APK: $(Split-Path $apkCand -Leaf)"
  Copy-Item -Force $apkCand $TargetApk
}
Write-Host "-> Canonical APK: $(Split-Path $TargetApk -Leaf)"

# 3) Quick integrity check (PK header)
$fs = [System.IO.File]::OpenRead($TargetApk)
try {
  $buf = New-Object byte[] 2
  $null = $fs.Read($buf,0,2)
  if (!($buf[0] -eq 0x50 -and $buf[1] -eq 0x4B)) {
    throw "APK doesn't look like a ZIP file (missing PK header)."
  }
} finally { $fs.Dispose() }

# 3b) Warn if permissions XML missing
if (-not (Test-Path $PermXml)) {
  Write-Warning "$PermXml not found. Some ROMs require this allowlist for privileged permissions."
}

# 4) Build the zip with Compress-Archive (include only what Magisk needs)
$items = @("module.prop","customize.sh","system")
foreach ($p in $items) {
  if (-not (Test-Path $p)) { throw "$p missing in repo root" }
}
if (Test-Path $Out) { Remove-Item -Force $Out }
Compress-Archive -Path $items -DestinationPath $Out -CompressionLevel Optimal

Write-Host "==> Done: $Out"