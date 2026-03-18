# 📱 Emülatör Test Rehberi

## ✅ Emülatör Başarıyla Başlatıldı!

**Emülatör:** Pixel 2 API 31 (Android 12)
**Device ID:** emulator-5554
**Durum:** ✅ Hazır

## 🚀 Uygulama Çalıştırma

Uygulama şu anda emülatörde çalıştırılıyor. İki yöntem var:

### Yöntem 1: Otomatik (Hazır Script)
```powershell
.\test_emulator.ps1
```

### Yöntem 2: Manuel
```powershell
cd c:\Users\Abdullah\Desktop\dijital_dini_takvim
flutter run -d emulator-5554
```

## 📊 Log Takibi

### Terminal 1: Uygulama (Flutter Run)
Loglar otomatik gösterilir. Beklenen loglar:
```
✅ Diyanet API: Authentication successful
✅ Diyanet API: Daily prayer times fetched
✅ Namaz vakitleri: Ankara
🔔 Notification service initialized: true
```

### Terminal 2: Filtreli Loglar (Opsiyonel)
```powershell
.\test_logs.ps1
```

VEYA:
```powershell
C:\Users\Abdullah\AppData\Local\Android\sdk\platform-tools\adb.exe logcat | Select-String -Pattern "Diyanet|Namaz|Bildirim|✅|❌"
```

## 🧪 Test Senaryoları

### 1. İlk Açılış
- [ ] Uygulama hatasız açılıyor mu?
- [ ] Splash screen görünüyor mu?
- [ ] Ana ekrana geçiyor mu?

### 2. Namaz Vakitleri
- [ ] Ana ekranda namaz vakitleri görünüyor mu?
- [ ] Namaz vakitleri ekranı açılıyor mu?
- [ ] Bugünün vakitleri doğru mu?

### 3. Bildirimler
- [ ] Bildirim izinleri isteniyor mu?
- [ ] Bildirim ayarları açılıyor mu?
- [ ] Test bildirimi gönderilebiliyor mu?

### 4. Dini Günler
- [ ] Dini günler ekranı açılıyor mu?
- [ ] Yaklaşan günler listeleniyor mu?

## 🔍 Önemli Notlar

### Emülatör Performansı
- İlk açılış yavaş olabilir (30-60 saniye)
- Emülatör RAM kullanır (en az 4GB önerilir)
- Emülatörü kapatmak için: Android Studio > AVD Manager > Stop

### Log Kontrolü
- Flutter run çalışırken loglar otomatik gösterilir
- Ctrl+C ile durdur
- 'r' tuşu ile hot reload
- 'R' tuşu ile hot restart

### Diyanet API Test
- İlk başlatmada authentication yapılır
- Token kaydedilir (SharedPreferences)
- Rate limit: 5 istek/gün (dikkatli kullanın!)

## 🐛 Sorun Giderme

### Emülatör açılmıyor
```powershell
# Emülatörleri listele
flutter emulators

# Farklı emülatör dene
flutter emulators --launch Pixel_9
```

### Uygulama çalışmıyor
```powershell
# Clean build
flutter clean
flutter pub get
flutter run -d emulator-5554
```

### Loglar görünmüyor
- Flutter run --verbose kullanın
- Veya ayrı terminalde test_logs.ps1 çalıştırın

## 📝 Test Sonuçları

Test tarihi: _______________

### Sonuçlar:
- [ ] Tüm testler başarılı
- [ ] Bazı testler başarısız

### Bulunan Hatalar:
1. 
2. 
3. 

### Notlar:

