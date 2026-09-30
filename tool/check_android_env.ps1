$ErrorActionPreference = 'Continue'
$ok = $true
Write-Host 'BMT GO v38 — проверка окружения сборки' -ForegroundColor Yellow
if (Get-Command flutter -ErrorAction SilentlyContinue) { flutter --version | Select-Object -First 2 } else { Write-Error 'Flutter не найден в PATH'; $ok=$false }
if (Get-Command java -ErrorAction SilentlyContinue) { java -version } else { Write-Error 'Java не найдена'; $ok=$false }
$sdk = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } elseif ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { $null }
if ($sdk) { Write-Host "Android SDK: $sdk" } else { Write-Warning 'ANDROID_SDK_ROOT/ANDROID_HOME не задан' }
$sdkmanager = Get-Command sdkmanager -ErrorAction SilentlyContinue
if ($sdkmanager) {
  $platform36 = Join-Path $sdk 'platforms/android-36/android.jar'
  if (Test-Path $platform36) { Write-Host 'OK: Android SDK Platform 36 установлена' -ForegroundColor Green } else { Write-Error 'Android SDK Platform 36 не найдена'; $ok=$false }
} else { Write-Warning 'sdkmanager не найден; проверка Platform 36 пропущена' }
if (Get-Command adb -ErrorAction SilentlyContinue) { Write-Host 'ADB найден' } else { Write-Warning 'ADB не найден (для сборки необязательно)' }
if (Get-Command flutter -ErrorAction SilentlyContinue) { flutter doctor -v }
if ($ok) { Write-Host 'ENVIRONMENT CHECK PASSED' -ForegroundColor Green } else { Write-Error 'ENVIRONMENT CHECK FAILED'; exit 1 }
