# Hızlı Test Script - PowerShell
# Kullanım: .\test_quick.ps1

Write-Host "🚀 Flutter Test Başlatılıyor..." -ForegroundColor Green
Write-Host ""

# Proje dizinine git
Set-Location "c:\Users\Abdullah\Desktop\dijital_dini_takvim"

# Cihazları kontrol et
Write-Host "📱 Bağlı cihazlar kontrol ediliyor..." -ForegroundColor Yellow
flutter devices

Write-Host ""
Write-Host "✅ Uygulama çalıştırılıyor..." -ForegroundColor Green
Write-Host "💡 Logları görmek için bu terminali açık tutun" -ForegroundColor Cyan
Write-Host "💡 Çıkmak için Ctrl+C basın" -ForegroundColor Cyan
Write-Host ""

# Uygulamayı çalıştır (verbose modda)
flutter run --verbose
