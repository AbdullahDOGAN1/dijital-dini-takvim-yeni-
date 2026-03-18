# Diyanet API Entegrasyonu - Test Checklist

## ✅ Yapılan Değişiklikler
- Tüm sistem Diyanet Awqat Salah API'ye geçirildi
- Token yönetimi ve refresh mekanizması eklendi
- Response parsing düzeltildi (tüm endpoint'lerde `{data: ..., success: true}` formatı)
- Şehir kodları mapping sistemi eklendi

## 🧪 Test Adımları

### 1. Uygulama Başlatma
- [ ] Uygulama hatasız başlıyor mu?
- [ ] Splash screen'den sonra ana ekrana geçiyor mu?
- [ ] Herhangi bir crash var mı?

### 2. Namaz Vakitleri Testi
- [ ] Ana ekranda namaz vakitleri görünüyor mu?
- [ ] Namaz vakitleri ekranı açılıyor mu?
- [ ] Bugünün namaz vakitleri doğru gösteriliyor mu?
- [ ] Aylık namaz vakitleri listesi yükleniyor mu?
- [ ] Gün güncellemesi çalışıyor mu? (Yarın test edin)

### 3. Bildirim Sistemi Testi
- [ ] Bildirim izinleri isteniyor mu?
- [ ] Bildirim ayarları ekranı açılıyor mu?
- [ ] Ezan öncesi bildirim ayarlanabiliyor mu? (örn: 20 dakika önce)
- [ ] Bildirim sesi seçilebiliyor mu?
- [ ] Test bildirimi gönderilebiliyor mu?
- [ ] Bildirim geldiğinde ses çalıyor mu?

**ÖNEMLİ:** Ezan vakti bildirimi için:
- [ ] Ezan vakti geldiğinde bildirim geliyor mu?
- [ ] Bildirime tıklandığında ezan sesi çalıyor mu?
- [ ] Ezan sesi 3 dakika sonra otomatik duruyor mu?

### 4. Dini Günler Testi
- [ ] Dini günler ekranı açılıyor mu?
- [ ] Yaklaşan dini günler listeleniyor mu?
- [ ] Bugünün dini günleri gösteriliyor mu?
- [ ] Dini gün detayları açılıyor mu?

### 5. Günlük İçerik Testi
- [ ] Ana ekranda günlük ayet/hadis görünüyor mu?
- [ ] Günlük içerik ekranı açılıyor mu?
- [ ] İçerik doğru yükleniyor mu?

### 6. Hicri Takvim Testi
- [ ] Hicri tarih gösteriliyor mu?
- [ ] Hicri takvim doğru mu?

### 7. Konum Servisi Testi
- [ ] Konum izni isteniyor mu?
- [ ] Konum ayarları ekranı açılıyor mu?
- [ ] Şehir seçimi çalışıyor mu?
- [ ] Seçilen şehre göre namaz vakitleri güncelleniyor mu?

### 8. Widget Testi (Android/iOS)
- [ ] Home screen widget'ları güncelleniyor mu?
- [ ] Widget'larda namaz vakitleri görünüyor mu?
- [ ] Widget'larda günlük içerik görünüyor mu?

## 🔍 Hata Kontrolü

### Console Logları
Uygulamayı çalıştırırken şu logları kontrol edin:

**Başarılı Durum:**
```
✅ Diyanet API: Authentication successful
✅ Diyanet API: Daily prayer times fetched for YYYY-MM-DD
✅ Namaz vakitleri: ŞehirAdı
```

**Hata Durumları:**
```
❌ Diyanet API: Authentication failed
❌ Cannot get prayer times: Authentication failed
⚠️ Diyanet API başarısız, JSON dosyasından okunuyor
```

### Yaygın Sorunlar ve Çözümleri

1. **"Authentication failed" hatası:**
   - Kullanıcı adı ve şifre doğru mu? (Secrets/Environment değerlerini kontrol edin)
   - İnternet bağlantısı var mı?
   - API rate limit'e takıldı mı? (5 istek/gün limiti var)

2. **Namaz vakitleri görünmüyor:**
   - Şehir kodu mapping'de var mı? (`DiyanetCityMapper`)
   - Console'da hata var mı?
   - Fallback JSON dosyasından okunuyor mu?

3. **Bildirimler çalışmıyor:**
   - Bildirim izinleri verildi mi?
   - Bildirim kanalları oluşturuldu mu?
   - Ses dosyaları assets'te var mı?

4. **Gün güncellenmiyor:**
   - `_lastLoadedDate` kontrolü çalışıyor mu?
   - `_isSameDay` fonksiyonu doğru mu?

## 📝 Test Sonuçları

Test tarihi: _______________
Test eden: _______________

### Sonuçlar:
- [ ] Tüm testler başarılı
- [ ] Bazı testler başarısız (detaylar aşağıda)

### Bulunan Hatalar:
1. 
2. 
3. 

### Notlar:

