# Emülatör Test Script - PowerShell
# Kullanım: .\test_emulator.ps1

Write-Host "🚀 Emülatör Test Başlatılıyor..." -ForegroundColor Green
Write-Host ""

# Proje dizinine git
Set-Location "c:\Users\Abdullah\Desktop\dijital_dini_takvim"

# Emülatörleri listele
Write-Host "📱 Mevcut emülatörler:" -ForegroundColor Yellow
flutter emulators

Write-Host ""
Write-Host "💡 Emülatör başlatılıyor (Pixel 2 API 31)..." -ForegroundColor Cyan
Write-Host "💡 Emülatör açılmasını bekleyin (30-60 saniye)..." -ForegroundColor Yellow
Write-Host ""

# Emülatörü başlat (arka planda)
Start-Process -FilePath "flutter" -ArgumentList "emulators", "--launch", "Pixel_2_API_31" -NoNewWindow

# 30 saniye bekle (emülatör açılsın)
Write-Host "⏳ Emülatör açılması bekleniyor (30 saniye)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Cihazları kontrol et
Write-Host ""
Write-Host "📱 Bağlı cihazlar kontrol ediliyor..." -ForegroundColor Yellow
flutter devices

Write-Host ""
Write-Host "✅ Uygulama çalıştırılıyor..." -ForegroundColor Green
Write-Host "💡 Logları görmek için bu terminali açık tutun" -ForegroundColor Cyan
Write-Host "💡 Çıkmak için Ctrl+C basın" -ForegroundColor Cyan
Write-Host ""

# Uygulamayı çalıştır (verbose modda)
flutter run --verbose
