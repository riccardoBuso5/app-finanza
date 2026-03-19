$ErrorActionPreference = 'Stop'

param(
  [string]$FlutterProjectPath = 'flutter_application_1',
  [switch]$SkipPubGet
)

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Join-Path $repoRoot $FlutterProjectPath
$buildDir = Join-Path $projectDir 'build'

if (-not (Test-Path $projectDir)) {
  throw "Cartella progetto Flutter non trovata: $projectDir"
}

Write-Host "Progetto Flutter: $projectDir"

if (Test-Path $buildDir) {
  Write-Host "Pulizia cartella build: $buildDir"
  Remove-Item -Path $buildDir -Recurse -Force
} else {
  Write-Host "Cartella build non presente, nessuna pulizia necessaria."
}

Push-Location $projectDir
try {
  if (-not $SkipPubGet) {
    Write-Host 'Eseguo flutter pub get...'
    flutter pub get
  }

  Write-Host 'Avvio app su Chrome...'
  flutter run -d chrome
}
finally {
  Pop-Location
}
