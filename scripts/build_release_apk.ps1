# Release APK with .env compiled in (OPENAI_API_KEY, API_BASE_URL, ...).
# String.fromEnvironment is compile-time: a plain `flutter build apk` ships empty keys.
# Usage: .\scripts\build_release_apk.ps1 [extra flutter args, e.g. --split-per-abi]
$root = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $root '.env'
if (-not (Test-Path $envFile)) { Write-Error ".env missing at $envFile (copy .env.example)"; exit 1 }
Push-Location $root
try {
  flutter build apk --release --dart-define-from-file=.env @args
  exit $LASTEXITCODE
} finally { Pop-Location }
