$ErrorActionPreference = 'Stop'
Write-Host 'BMT GO v38 — сборка релизного AAB' -ForegroundColor Yellow
& "$PSScriptRoot/check_android_env.ps1"
$supabaseUrl = Read-Host 'SUPABASE_URL'
$supabaseAnon = Read-Host 'SUPABASE_ANON_KEY'
$mapsKey = Read-Host 'GOOGLE_MAPS_API_KEY'
if ([string]::IsNullOrWhiteSpace($supabaseUrl) -or [string]::IsNullOrWhiteSpace($supabaseAnon) -or [string]::IsNullOrWhiteSpace($mapsKey)) { throw 'Все три значения обязательны.' }
flutter clean
flutter pub get
flutter build appbundle --release `
  --dart-define="SUPABASE_URL=$supabaseUrl" `
  --dart-define="SUPABASE_ANON_KEY=$supabaseAnon" `
  --dart-define="GOOGLE_MAPS_API_KEY=$mapsKey"
$artifact = Join-Path (Get-Location) 'build/app/outputs/bundle/release/app-release.aab'
if (-not (Test-Path $artifact)) { throw "AAB не найден: $artifact" }
Write-Host "ГОТОВО: $artifact" -ForegroundColor Green
