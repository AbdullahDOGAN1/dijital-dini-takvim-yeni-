# ADB Sürücü Sorunu Çözümü

## 🔍 Sorun
Telefon Windows'ta görünüyor ama ADB ile görünmüyor. "MTP USB Aygıtı" görünüyor ama "Android Composite ADB Interface" görünmüyor.

## ✅ Çözüm Adımları

### 1. Telefonu PTP Moduna Alın
1. Telefonda bildirim alanını açın
2. "USB ile bağlandı" veya "USB seçenekleri" bildirimine tıklayın
3. **"PTP" (Picture Transfer Protocol)** seçeneğini seçin
   - VEYA **"Dosya Aktarımı"** (File Transfer) seçeneğini seçin
   - **"MTP" değil, "PTP" veya "File Transfer" olmalı**

### 2. Cihaz Yöneticisinde Kontrol
1. Windows tuşu + X > **Cihaz Yöneticisi**
2. Telefon bağlıyken şunları kontrol edin:
   - **"Android Phone"** veya **"Portable Devices"** altında telefon görünmeli
   - **"Android Composite ADB Interface"** görünmeli
   - Eğer **"MTP USB Device"** görünüyorsa ve sarı ünlem işareti varsa:
     - Sağ tık > **"Sürücü yazılımını güncelle"**
     - **"Bilgisayarımda sürücü yazılımı ara"**
     - **"Bilgisayarımdaki kullanılabilir sürücüler listesinden seç"**
     - **"Android Composite ADB Interface"** seçin

### 3. Google USB Driver Yükleme
1. Android Studio'yu açın
2. **Tools** > **SDK Manager**
3. **SDK Tools** sekmesine gidin
4. **"Google USB Driver"** işaretleyin
5. **Apply** > **OK**

VEYA manuel:
1. https://developer.android.com/studio/run/win-usb adresine gidin
2. **"Google USB Driver"** indirin
3. Cihaz Yöneticisi'nde sürücüyü güncelleyin

### 4. ADB Sürücüsünü Manuel Yükleme
1. Cihaz Yöneticisi'nde telefonu bulun (MTP USB Device veya Unknown Device)
2. Sağ tık > **"Sürücü yazılımını güncelle"**
3. **"Bilgisayarımda sürücü yazılımı ara"**
4. **"Bilgisayarımdaki kullanılabilir sürücüler listesinden seç"**
5. **"Android Device"** veya **"Android Composite ADB Interface"** seçin
6. Eğer listede yoksa:
   - **"Disk'ten yükle"** seçin
   - Android SDK path: `C:\Users\Abdullah\AppData\Local\Android\sdk\extras\google\usb_driver`
   - Veya: `C:\Users\Abdullah\AppData\Local\Android\sdk\extras\google\usb_driver\android_winusb.inf`

### 5. Telefonda Kontrol
1. **USB Debugging** açık mı? (Ayarlar > Geliştirici Seçenekleri)
2. Telefonda **"USB Debugging"** bildirimi görünüyor mu?
3. İlk bağlantıda **"Bu bilgisayara güven"** onayladınız mı?

### 6. Test
```powershell
# ADB server'ı restart et
C:\Users\Abdullah\AppData\Local\Android\sdk\platform-tools\adb.exe kill-server
C:\Users\Abdullah\AppData\Local\Android\sdk\platform-tools\adb.exe start-server

# Cihazları kontrol et
C:\Users\Abdullah\AppData\Local\Android\sdk\platform-tools\adb.exe devices
```

**Başarılı çıktı:**
```
List of devices attached
ABC123XYZ    device
```

## 🔄 Alternatif: Wireless Debugging (Android 11+)

Eğer USB ile çalışmazsa:

1. Telefonda: **Geliştirici Seçenekleri** > **Wireless Debugging**
2. Açın ve **"Eşleştirme kodu ile eşleştir"** seçin
3. IP adresi ve portu not edin (örn: 192.168.1.100:5555)
4. PowerShell'de:
```powershell
C:\Users\Abdullah\AppData\Local\Android\sdk\platform-tools\adb.exe connect 192.168.1.100:5555
```

## 💡 İpuçları

- **PTP modu** genellikle ADB için daha iyi çalışır
- **MTP modu** dosya aktarımı için, ADB için değil
- Telefonu **PTP'ye** alınca ADB interface görünmeli
- İlk bağlantıda telefon sizden **"Bu bilgisayara güven"** onayı ister
