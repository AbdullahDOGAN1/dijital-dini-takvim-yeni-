# Log Kaydetme Script - PowerShell
# Kullanım: .\test_logs_save.ps1
# Logları dosyaya kaydeder

Write-Host "💾 Loglar dosyaya kaydediliyor..." -ForegroundColor Green

# Zaman damgalı dosya adı
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = "test_logs_$timestamp.txt"

Write-Host "📝 Log dosyası: $logFile" -ForegroundColor Cyan
Write-Host "💡 Durdurmak için Ctrl+C basın" -ForegroundColor Yellow
Write-Host ""

# Logları dosyaya kaydet
adb logcat -v time | Tee-Object -FilePath $logFile | Select-String -Pattern "Diyanet|Namaz|Prayer|Bildirim|Notification|Ezan|✅|❌|⚠️|🔔|🕌|📅"

Write-Host ""
Write-Host "✅ Loglar kaydedildi: $logFile" -ForegroundColor Green
