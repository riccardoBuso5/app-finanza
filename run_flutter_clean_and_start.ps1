param(
  [string]$FlutterProjectPath = 'flutter_application_1',
  [switch]$SkipPubGet,
  [string]$Device = 'chrome'

)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Join-Path $repoRoot $FlutterProjectPath
$buildDir = Join-Path $projectDir 'build'
$backendDir = Join-Path $repoRoot 'backend'

if(-not (Test-Path $backendDir)) {
  throw "Cartella backend non trovata: $backendDir"
}else{
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
  if (-not $SkipPubGet) {
    Write-Host 'Eseguo flutter pub get...'
    flutter pub get
  }

  if ($Device -eq 'chrome') {
      Write-Host 'Avvio app su Chrome...'
      flutter run -d chrome
  } elseif ($Device -eq 'emulator') {
      Write-Host 'Avvio app su emulatore Android (emulator-5554)...'
      flutter run -d emulator-5554
  } else {
      Write-Host "Avvio app sul device specificato: $Device"
      flutter run -d $Device
  }
}
finally {
  Pop-Location
}
