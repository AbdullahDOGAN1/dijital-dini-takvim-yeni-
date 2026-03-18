# Log Takip Script - PowerShell
# Kullanım: .\test_logs.ps1
# Not: Bu script ayrı bir terminalde çalıştırılmalı (flutter run çalışırken)

Write-Host "📊 Log Takibi Başlatılıyor..." -ForegroundColor Green
Write-Host "💡 Bu script'i flutter run çalışırken ayrı terminalde çalıştırın" -ForegroundColor Yellow
Write-Host ""

# Android logcat ile logları filtrele
Write-Host "🔍 Diyanet API ve Namaz Vakitleri logları filtreleniyor..." -ForegroundColor Cyan
Write-Host ""

# Renkli ve filtreli loglar
adb logcat -v color | Select-String -Pattern "Diyanet|Namaz|Prayer|Bildirim|Notification|Ezan|✅|❌|⚠️|🔔|🕌|📅"

# Alternatif: Sadece Flutter logları
# adb logcat | Select-String -Pattern "flutter"
