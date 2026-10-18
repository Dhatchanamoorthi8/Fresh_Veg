# Vegora Admin & Staff Portal - 1-Click Vercel Deploy Script
$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Green
Write-Host "  Vegora Admin & Staff Portal Vercel Deploy" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

# 1. Navigate to admin web project
Set-Location "apps\vegora_admin_web"

# 2. Get dependencies
Write-Host "`n[1/3] Resolving dependencies..." -ForegroundColor Yellow
flutter pub get

# 3. Build release web bundle
Write-Host "`n[2/3] Building production web bundle..." -ForegroundColor Yellow
flutter build web --release --base-href "/"

# 4. Copy vercel.json if not present
if (-not (Test-Path "build\web\vercel.json")) {
    Copy-Item "web\vercel.json" -Destination "build\web\vercel.json"
}

# 5. Deploy to Vercel
Write-Host "`n[3/3] Deploying to Vercel production..." -ForegroundColor Yellow
npx vercel deploy build\web --prod

Write-Host "`n Deployment complete!" -ForegroundColor Green
