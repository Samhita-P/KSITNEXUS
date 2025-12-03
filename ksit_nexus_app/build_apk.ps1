# Build APK script that works around path space issues
$ErrorActionPreference = "Stop"

Write-Host "Building APK (working around path space issues)..." -ForegroundColor Green

# Create temporary build directory without spaces (with timestamp to avoid conflicts)
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$tempBuildDir = "C:\KSIT_TEMP_BUILD_$timestamp"
if (Test-Path $tempBuildDir) {
    Remove-Item $tempBuildDir -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $tempBuildDir -Force | Out-Null

# Get current directory
$currentDir = Get-Location

try {
    # Copy project to temp location using robocopy (excludes build dirs)
    Write-Host "Copying project to temporary location..." -ForegroundColor Yellow
    robocopy $currentDir $tempBuildDir /E /XD build .dart_tool .gradle android\.gradle android\build android\app\build /NFL /NDL /NJH /NJS /NP
    
    # Build from temp location
    Write-Host "Building APK from temporary location..." -ForegroundColor Yellow
    Push-Location $tempBuildDir
    flutter clean
    flutter pub get
    flutter build apk --release
    
    # Copy APK back
    $apkPath = Get-ChildItem -Path "$tempBuildDir\build\app\outputs\flutter-apk" -Filter "*.apk" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($apkPath) {
        $destPath = Join-Path $currentDir "build\app\outputs\flutter-apk\app-release.apk"
        New-Item -ItemType Directory -Path (Split-Path $destPath) -Force | Out-Null
        Copy-Item $apkPath.FullName $destPath -Force
        Write-Host "`n✅ APK built successfully!" -ForegroundColor Green
        Write-Host "Location: $destPath" -ForegroundColor Cyan
        Write-Host "Size: $((Get-Item $destPath).Length / 1MB) MB" -ForegroundColor Cyan
    } else {
        Write-Host "❌ APK not found after build" -ForegroundColor Red
        exit 1
    }
} finally {
    Pop-Location
    # Cleanup
    if (Test-Path $tempBuildDir) {
        Remove-Item $tempBuildDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

