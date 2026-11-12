# Interactive Tales - Release Build Automation Script
# Generates the signed Android App Bundle (.aab) for Google Play Store upload

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "🚀 STARTING BUILD AUTOMATION PIPELINE" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 1. Flutter Clean
Write-Host "`n🧹 Step 1/4: Cleaning previous build files..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ 'flutter clean' failed."
    exit 1
}

# 2. Flutter Pub Get
Write-Host "`n📦 Step 2/4: Resolving and fetching dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ 'flutter pub get' failed."
    exit 1
}

# 3. Code Verification
Write-Host "`n🔍 Step 3/4: Running code static analysis..." -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ 'flutter analyze' detected issues. Build aborted."
    exit 1
}

# 4. Flutter Build App Bundle
Write-Host "`n🏗️ Step 4/4: Compiling signed Android App Bundle (.aab) in release mode..." -ForegroundColor Yellow
flutter build appbundle --release
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ 'flutter build appbundle' failed."
    exit 1
}

Write-Host "`n=============================================" -ForegroundColor Green
Write-Host "🎉 BUILD SUCCESSFUL! READY FOR GOOGLE PLAY" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
$aabPath = Resolve-Path "build/app/outputs/bundle/release/app-release.aab"
Write-Host "AAB File Location: $aabPath" -ForegroundColor Cyan
