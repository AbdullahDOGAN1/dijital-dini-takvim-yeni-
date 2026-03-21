# Diyanet API Kapsam Matrisi (Faz 1)

## 1. Diyanet Awqat Salah API Kararları
- **Auth:** `POST /Auth/Login` (Çalışıyor)
- **Konumlar:** `GET /api/v2/Place/Cities` (Sadece TR filtresi ile çalışıyor)
- **Namaz Vakitleri (Toplu Caching):** `POST /api/PrayerTime/DateRange` (30-40 günlük veri çekmek için başarılı)
- **Dini Günler:** `GET /api/ReligiousDays` (Çalışıyor ancak API geçmiş/gelecek bazı yıllarda 404 dönebiliyor, bu yüzden `sync-diyanet-to-json.js` içinde fallback koruması mevcut).

## 2. API'de Çalışmayan / Desteklenmeyenler ve Stratejiler
- **Hicri Takvim:** API'nin bağımsız `HijriCalendar` endpointi yoktur (404 döner).
  *Strateji:* Hicri takvim verisini ya Namaz vakitleri endpointinden düşen `Shape` içinden ayıklayacağız ya da offline Dart kütüphanesi/static dosyası (#Fallback) ile çözeceğiz. Uygulamadaki offline kütüphane en iyisidir.
- **Günlük İçerik (Ayet/Hadis/Dua):** `GET /api/DailyContent` endpointi vardır ancak tarih parametresi almaz ve sadece o günün bilgisini döner. GitHub Actions (aylık çalıştığı için) 30 günün ayet ve hadisini önceden toplayamaz.
  *Strateji:* Uygulamanın içerisindeki mevcut günlük içerik dosyası (`assets/...`) veya yerel eski altyapı kullanılmaya devam edilecek (Faz 4/6'da kesinleşecek). Ayda 1 kez çekme senaryosuna Awqat Salah DailyContent uymuyor.
- **Kıble:** Kıble endpoint'i net çalışmıyor ve zaten Flutter içinde yerel GPS/Compass ile offline hesaplanması (eski sistem) sorunsuz. Değiştirilmeyecek.

> **Sonuç:** Mimarinin temel cache girdisi: Şehirler bazında 40 günlük "PrayerTime" (Namaz ve ardışık Hicri gün) ile o yıla ait "ReligiousDays" (Dini günler JSON) verileridir. Geri kalan kalemler offline çalıştırılacaktır.
