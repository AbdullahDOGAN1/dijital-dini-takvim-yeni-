# Test Komutları ve Log Takibi

## 📱 Telefona Bağlanma

### Android
```bash
# 1. USB Debugging açık mı kontrol et
adb devices

# 2. Cihaz görünüyorsa hazırsınız
# Örnek çıktı:
# List of devices attached
# ABC123XYZ    device
```

### iOS (Mac gerekli)
```bash
# iOS cihazları için Xcode gerekli
# Cihazları kontrol et:
xcrun simctl list devices
```

## 🚀 Uygulamayı Çalıştırma

### Flutter Run (En İyi Yöntem - Logları Canlı Gösterir)
```bash
# Proje dizinine git
cd c:\Users\Abdullah\Desktop\dijital_dini_takvim

# Debug modda çalıştır (loglar otomatik gösterilir)
flutter run

# Veya belirli bir cihaz seç
flutter devices  # Mevcut cihazları listele
flutter run -d <device-id>
```

### Sadece Build (Log olmadan)
```bash
flutter build apk --debug  # Android
flutter build ios --debug   # iOS (Mac gerekli)
```

## 📊 Log Takibi

### 1. Flutter Run ile (Önerilen)
```bash
flutter run
# Tüm loglar otomatik gösterilir
# Ctrl+C ile durdur
```

### 2. Android Logcat (Detaylı Android Logları)
```bash
# Tüm logları göster
adb logcat

# Sadece Flutter logları
adb logcat | grep flutter

# Sadece bizim logları (Diyanet API, Namaz Vakitleri vb.)
adb logcat | grep -E "Diyanet|Namaz|Bildirim|Prayer"

# Renkli ve filtreli
adb logcat -v color | grep -E "✅|❌|⚠️|🔔|🕌|📅"

# Belirli bir tag'e göre filtrele
adb logcat -s flutter:V DiyanetAPI:V NotificationService:V
```

### 3. iOS Console (Mac gerekli)
```bash
# Xcode Console'u kullan veya:
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "Runner"'
```

### 4. Flutter Logs (Platform Bağımsız)
```bash
# Flutter run çalışırken başka terminalde:
flutter logs

# Veya belirli bir cihaz için:
flutter logs -d <device-id>
```

## 🔍 Önemli Log Filtreleri

### Diyanet API Logları
```bash
# Windows PowerShell
adb logcat | Select-String -Pattern "Diyanet|Authentication|Token"

# Linux/Mac
adb logcat | grep -i "diyanet\|authentication\|token"
```

### Namaz Vakitleri Logları
```bash
adb logcat | grep -E "Namaz|Prayer|İmsak|Öğle|Akşam"
```

### Bildirim Logları
```bash
adb logcat | grep -E "Bildirim|Notification|Ezan|🔔"
```

### Hata Logları
```bash
# Sadece hatalar
adb logcat *:E

# Hatalar ve uyarılar
adb logcat *:W
```

## 🎯 Test Senaryoları için Özel Komutlar

### Senaryo 1: Namaz Vakitleri Testi
```bash
# Terminal 1: Uygulamayı çalıştır
flutter run

# Terminal 2: Sadece namaz vakitleri logları
adb logcat | grep -E "Prayer|Namaz|Diyanet.*prayer"
```

### Senaryo 2: Bildirim Testi
```bash
# Terminal 1: Uygulamayı çalıştır
flutter run

# Terminal 2: Bildirim logları
adb logcat | grep -E "Notification|Bildirim|Ezan|🔔"
```

### Senaryo 3: API Authentication Testi
```bash
# Terminal 1: Uygulamayı çalıştır
flutter run

# Terminal 2: API logları
adb logcat | grep -E "Diyanet|Authentication|Token|API"
```

## 📝 Log Dosyasına Kaydetme

### Tüm logları dosyaya kaydet
```bash
# Windows PowerShell
adb logcat > test_logs.txt

# Linux/Mac
adb logcat > test_logs.txt

# Sadece bizim logları
adb logcat | grep -E "Diyanet|Namaz|Bildirim" > test_logs.txt
```

### Zaman damgalı log
```bash
# Windows PowerShell
adb logcat -v time > "test_logs_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Linux/Mac
adb logcat -v time > "test_logs_$(date +%Y%m%d_%H%M%S).txt"
```

## 🛠️ Hızlı Test Komutları

### Tek Komutla Test
```bash
# Uygulamayı çalıştır ve logları göster
flutter run --verbose
```

### Hot Reload ile Test
```bash
# Uygulama çalışırken:
# - 'r' tuşu: Hot reload
# - 'R' tuşu: Hot restart
# - 'q' tuşu: Çıkış
```

## 🔧 Sorun Giderme

### Cihaz görünmüyor
```bash
# Android
adb kill-server
adb start-server
adb devices

# USB Debugging açık mı kontrol et (Telefon Ayarları > Geliştirici Seçenekleri)
```

### Loglar görünmüyor
```bash
# Flutter clean
flutter clean
flutter pub get
flutter run
```

### Eski logları temizle
```bash
adb logcat -c  # Log buffer'ı temizle
```

## 📱 Test Sırası

1. **Terminal 1:** `flutter run` (Uygulamayı çalıştır)
2. **Terminal 2:** `adb logcat | grep -E "✅|❌|⚠️|🔔"` (Logları filtrele)
3. Uygulamada test senaryolarını çalıştır
4. Logları gözlemle

## 💡 İpuçları

- **Flutter run** en iyi yöntem - hem uygulamayı çalıştırır hem logları gösterir
- **Ctrl+C** ile durdur, **'r'** ile hot reload yap
- **--verbose** flag'i daha detaylı loglar verir
- Logları dosyaya kaydedip sonra analiz edebilirsiniz
