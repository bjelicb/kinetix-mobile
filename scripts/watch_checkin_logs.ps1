# PowerShell script za praćenje check-in logova
# Koristi ovaj script kada testiraš offline check-in

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "CHECK-IN LOGS WATCHER" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Proveri da li postoji device
Write-Host "Checking for connected devices..." -ForegroundColor Yellow
$devices = adb devices
Write-Host $devices

Write-Host ""
Write-Host "Starting logcat with filters for Check-In..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

# Filtriraj samo relevantne logove za check-in
# Koristi sledeće tag-ove:
# - CheckInService
# - CheckInQueue
# - SyncManager (media sync)
# - RemoteDataSource (API calls)
# - LocalDataSource (database operations)

adb logcat -c  # Clear existing logs first

adb logcat | Select-String -Pattern "CheckIn|SyncManager.*MEDIA|RemoteDataSource.*checkin|LocalDataSource.*CheckIn" -Context 2,2

