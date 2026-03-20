param(
  [string]$FlutterProjectPath = 'flutter_application_1',
  [switch]$SkipPubGet,
  [string]$Device = 'chrome',
  [string]$ApiBaseUrl = ''

)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Join-Path $repoRoot $FlutterProjectPath
$buildDir = Join-Path $projectDir 'build'
$backendDir = Join-Path $repoRoot 'backend'

if(-not (Test-Path $backendDir)) {
  throw "Cartella backend non trovata: $backendDir"
}else{
  if ($ApiBaseUrl.Trim().Length -gt 0) {
    Write-Host "API remota impostata: salto avvio backend locale."
  } else {
    Write-Host "Avvio backend in un nuovo terminale..."
    $backendCommand = "& { Set-Location -LiteralPath '$backendDir'; npm install; npm start }"
    Start-Process -FilePath 'powershell.exe' -ArgumentList @(
      '-NoExit',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      $backendCommand
    )
  }
} 


if (-not (Test-Path $projectDir)) {
  throw "Cartella progetto Flutter non trovata: $projectDir"
}

Write-Host "Progetto Flutter: $projectDir"

if (Test-Path $buildDir) {
  Write-Host "Pulizia cartella build: $buildDir"
  try {
    Remove-Item -Path $buildDir -Recurse -Force -ErrorAction Stop
  } catch {
    Write-Warning "Pulizia standard fallita: $($_.Exception.Message)"
  }
} else {
  Write-Host "Cartella build non presente, nessuna pulizia necessaria."
}

Push-Location $projectDir
try {
  $flutterArgs = @('run', '-d')
  if ($Device -eq 'chrome') {
    $flutterArgs += 'chrome'
  } elseif ($Device -eq 'emulator') {
    $flutterArgs += 'emulator-5554'
  } else {
    $flutterArgs += $Device
  }

  if ($ApiBaseUrl.Trim().Length -gt 0) {
    Write-Host "Uso API base URL remoto: $ApiBaseUrl"
    $flutterArgs += "--dart-define=API_BASE_URL=$ApiBaseUrl"
  }

  if (-not $SkipPubGet) {
    Write-Host 'Eseguo flutter pub get...'
    flutter pub get
  }

  if ($Device -eq 'chrome') {
      Write-Host 'Avvio app su Chrome...'
      flutter @flutterArgs
  } elseif ($Device -eq 'emulator') {
      Write-Host 'Avvio app su emulatore Android (emulator-5554)...'
      flutter @flutterArgs
  } else {
      Write-Host "Avvio app sul device specificato: $Device"
      flutter @flutterArgs
  }
}
finally {
  Pop-Location
}
