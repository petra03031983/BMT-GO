$ErrorActionPreference='Stop'
Set-Location (Join-Path $PSScriptRoot '..')
$fail=$false
function Ok($m){Write-Host "OK  $m" -ForegroundColor Green}
function Fail($m){Write-Host "FAIL $m" -ForegroundColor Red; $script:fail=$true}
$s=Get-Content pubspec.yaml -Raw
if($s -match '(?m)^version: 1\.18\.0\+41$'){Ok 'pubspec version 1.18.0+41'}else{Fail 'pubspec version'}
$g=Get-Content android/app/build.gradle -Raw
if($g -match "applicationId\s+['\"]com\.bmtgo\.app['\"]"){Ok 'applicationId com.bmtgo.app'}else{Fail 'applicationId'}
foreach($x in @('compileSdk 36','targetSdk 36','versionCode 41')){if($g.Contains($x)){Ok $x}else{Fail $x}}
if((Get-Item docs/privacy_policy_ru.html).Length -gt 0){Ok 'privacy policy exists'}else{Fail 'privacy policy'}
if((Get-Content docs/privacy_policy_ru.html -Raw).Contains('petra03031983@gmail.com')){Ok 'privacy support email'}else{Fail 'privacy support email'}
if((Get-Item docs/account_deletion.html).Length -gt 0){Ok 'account deletion page exists'}else{Fail 'account deletion page'}
if((Get-Content docs/account_deletion.html -Raw).Contains('petra03031983@gmail.com')){Ok 'account deletion support email'}else{Fail 'account deletion support email'}
$files=Get-ChildItem docs,android/app,lib -Recurse -File -ErrorAction SilentlyContinue | Where-Object {$_.Name -notlike '*.example'}
$hits=$files | Select-String -Pattern 'УКАЖИТЕ_РАБОЧИЙ_EMAIL|Добавьте здесь официальный e-mail|example\.com|YOUR_[A-Z_]+|REPLACE_ME|CHANGE_ME' -AllMatches
if($hits){Fail 'release placeholders found'; $hits | ForEach-Object {Write-Host ($_.Path+':'+$_.LineNumber+':'+$_.Line.Trim())}}else{Ok 'no release placeholders'}
if(Get-Command flutter -ErrorAction SilentlyContinue){Ok 'Flutter available'}else{Write-Warning 'Flutter not installed in this environment'}
if($env:ANDROID_SDK_ROOT -and (Test-Path (Join-Path $env:ANDROID_SDK_ROOT 'platforms/android-36/android.jar'))){Ok 'Android SDK Platform 36'}else{Write-Warning 'Android SDK Platform 36 not verified here'}
if($fail){throw 'V41 RELEASE GATE FAILED'}else{Write-Host 'V41 RELEASE GATE PASSED' -ForegroundColor Green}
