# Release build with .env compiled in (API_BASE_URL, OPENAI_API_KEY, ...).
# String.fromEnvironment is compile-time: a plain `flutter build` ships empty keys.
#
# Usage:
#   .\scripts\build_release_apk.ps1                  # universal APK (as before)
#   .\scripts\build_release_apk.ps1 -Bundle          # Play Store app bundle (.aab):
#                                                    # each phone downloads only its ABI
#   .\scripts\build_release_apk.ps1 --split-per-abi  # extra flutter args pass through
#
# Dart code is obfuscated; the symbols needed to read crash stack traces go to
# build/symbols/<version>. Keep that folder (and
# build/app/outputs/mapping/release/mapping.txt) for every version you ship:
#   flutter symbolize -i <stack.txt> -d build/symbols/<version>/app.android-arm64.symbols
param([switch]$Bundle)

$root = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $root '.env'
if (-not (Test-Path $envFile)) { Write-Error ".env missing at $envFile (copy .env.example)"; exit 1 }

$version = (Select-String -Path (Join-Path $root 'pubspec.yaml') -Pattern '^version:\s*(\S+)').Matches[0].Groups[1].Value
$symbols = Join-Path $root "build/symbols/$version"

Push-Location $root
try {
  $common = @('--release', '--dart-define-from-file=.env', '--obfuscate', "--split-debug-info=$symbols")
  if ($Bundle) {
    flutter build appbundle @common @args
  } else {
    flutter build apk @common @args
  }
  $code = $LASTEXITCODE
  if ($code -eq 0) {
    Write-Host "Debug symbols: $symbols (keep these for crash symbolication)"
    # Crashlytics needs the Dart symbols to show readable stacks for obfuscated
    # builds (Firebase CLI: npm i -g firebase-tools; firebase login). The R8
    # mapping file is uploaded by the Crashlytics Gradle plugin during the build.
    if (Get-Command firebase -ErrorAction SilentlyContinue) {
      firebase crashlytics:symbols:upload --app=1:1033527417367:android:283b66ae3fdd8ed21b5a52 $symbols
    } else {
      Write-Warning "Firebase CLI not found: upload $symbols to Crashlytics manually."
    }
  }
  exit $code
} finally { Pop-Location }
