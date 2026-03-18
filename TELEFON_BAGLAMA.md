# 📱 Telefon Bağlama Rehberi

## Android Telefon İçin

### 1. USB Debugging Açma
1. Telefonunuzda **Ayarlar** > **Telefon Hakkında** (About Phone)
2. **Yapı Numarası** (Build Number) üzerine **7 kez** tıklayın
3. Geri dönün: **Ayarlar** > **Geliştirici Seçenekleri** (Developer Options)
4. **USB Debugging** seçeneğini **AÇIN**
5. İsteğe bağlı: **USB ile yükleme** (USB Install) seçeneğini de açın

### 2. Telefonu Bilgisayara Bağlama
1. USB kablosu ile telefonu bilgisayara bağlayın
2. Telefonda **"Bu bilgisayara güven"** (Trust this computer) uyarısını onaylayın
3. USB bağlantı modunu **"Dosya Aktarımı"** (File Transfer) veya **"MTP"** olarak seçin

### 3. Bağlantıyı Kontrol Etme
```powershell
# PowerShell'de çalıştırın:
adb devices
```

**Başarılı çıktı:**
```
List of devices attached
ABC123XYZ    device
```

**Sorun varsa:**
- USB kablosunu değiştirin
- USB portunu değiştirin
- Telefonda USB debugging'i kapatıp açın
- `adb kill-server` sonra `adb start-server` çalıştırın

## iOS Telefon İçin (Mac gerekli)

1. Xcode'u yükleyin
2. Telefonu USB ile bağlayın
3. Xcode'da **Window** > **Devices and Simulators**
4. Telefonunuzu seçin ve **"Trust"** butonuna tıklayın

## 📋 Hızlı Test Adımları

### Adım 1: Telefonu Bağla
- USB kablosu ile bağlayın
- USB Debugging açık olsun

### Adım 2: Bağlantıyı Kontrol Et
```powershell
cd c:\Users\Abdullah\Desktop\dijital_dini_takvim
flutter devices
```

Telefonunuz listede görünmeli:
```
Found X connected devices:
  ...
  sdk gphone64 arm64 (mobile) • emulator-5554 • android-arm64  • Android 14 (API 34)
  ...
```

### Adım 3: Uygulamayı Çalıştır
**Yöntem 1: PowerShell Script (Kolay)**
```powershell
.\test_quick.ps1
```

**Yöntem 2: Manuel**
```powershell
flutter run
```

### Adım 4: Logları Takip Et (Ayrı Terminal)
**Yöntem 1: PowerShell Script**
```powershell
# Yeni bir PowerShell penceresi açın
.\test_logs.ps1
```

**Yöntem 2: Manuel**
```powershell
adb logcat | Select-String -Pattern "Diyanet|Namaz|Bildirim|✅|❌"
```

## 🔧 Sorun Giderme

### "adb: command not found"
- Android SDK Platform Tools yüklü değil
- Flutter SDK içinde olmalı: `C:\Users\Abdullah\AppData\Local\Android\Sdk\platform-tools`
- PATH'e ekleyin veya tam yol ile çalıştırın

### Telefon görünmüyor
1. USB Debugging açık mı kontrol edin
2. USB kablosunu değiştirin
3. `adb kill-server` sonra `adb start-server`
4. Telefonda "Bu bilgisayara güven" onaylayın

### "unauthorized" hatası
- Telefonda USB debugging uyarısını onaylayın
- "Bu bilgisayara güven" seçeneğini işaretleyin

## 💡 İpuçları

- **İlk bağlantıda** telefon sizden onay isteyecek
- **Her seferinde** USB debugging açık olmalı
- **USB kablosu** veri aktarımı yapabilmeli (sadece şarj kablosu olmaz)
- **Flutter run** çalışırken loglar otomatik gösterilir
