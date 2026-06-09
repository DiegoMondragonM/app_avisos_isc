# Copia los iconos al proyecto y genera los mipmaps del launcher.
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path $PSScriptRoot -Parent
$srcDir = Join-Path $env:USERPROFILE '.cursor\projects\c-Users-momd0-Documents-SEMESTRE-8TAVO-TALLER-INV-2-app-avisosisc-isc-ccn\assets'
$imagesDir = Join-Path $projectRoot 'assets\images'
$drawableDir = Join-Path $projectRoot 'android\app\src\main\res\drawable'

New-Item -ItemType Directory -Force -Path $imagesDir | Out-Null
New-Item -ItemType Directory -Force -Path $drawableDir | Out-Null

$appIcon = Join-Path $imagesDir 'icon.png'
$notifIcon = Join-Path $imagesDir 'icon2.png'

if (-not (Test-Path $appIcon) -or -not (Test-Path $notifIcon)) {
  Write-Error 'Coloca icon.png (app) e icon2.png (notificaciones) en assets/images/.'
}

Copy-Item $notifIcon (Join-Path $drawableDir 'ic_notification.png') -Force

Set-Location $projectRoot
flutter pub get
dart run flutter_launcher_icons

Write-Host 'Iconos configurados correctamente.' -ForegroundColor Green
