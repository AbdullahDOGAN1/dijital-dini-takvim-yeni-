# Firebase Blaze Olmadan Kurulum (Ücretsiz Yol)

Bu yöntem Firebase Cloud Functions deploy gerektirmez.
Veri senkronu GitHub Actions ile aylık yapılır ve JSON dosyaları repo içine yazılır.
Uygulama da bu JSON cache'i kullanır.

Bu repo artık varsayılan olarak **tek kaynak** modunda çalışır:
- Mobil uygulama: JSON cache-first
- Senkron: GitHub Actions (aylık)
- Firebase endpoint workflow: devreden kaldırıldı

## 1) GitHub Secrets

Repo -> Settings -> Secrets and variables -> Actions bölümüne ekleyin:

- `DIYANET_EMAIL`
- `DIYANET_PASSWORD`

## 2) Workflow Çalıştırma

Workflow adı: `Diyanet Monthly JSON Sync (No Blaze)`

- Elle ilk kez çalıştırın (`Run workflow`)
- Sonraki aylarda otomatik çalışır (her ayın 1'i)

Başarılı çalışınca şu dosya güncellenir:

- `assets/data/diyanet_cache/prayer_times_window.json`
- `assets/data/diyanet_cache/religious_days_<year>.json`
- `assets/data/diyanet_cache/sync_status.json`

## 3) Mobil Uygulama

`PrayerApiService` artık Firestore yerine JSON cache-first çalışır.
Doğrudan Diyanet API fallback varsayılan olarak kapalıdır.

Varsayılan kaynak:

- `https://raw.githubusercontent.com/AbdullahDOGAN1/dijital-dini-takvim-yeni-/main/assets/data/diyanet_cache`

Farklı repo/branch kullanmak istersen build sırasında:

```bash
flutter run --dart-define=DIYANET_CACHE_BASE_URL=https://raw.githubusercontent.com/<owner>/<repo>/<branch>/assets/data/diyanet_cache
```

Doğrudan API fallback'i geçici açmak istersen:

```bash
flutter run --dart-define=ENABLE_DIRECT_DIYANET_API=true
```

## Notlar

- Bu yol 0₺ ile ayağa kalkar.
- Firebase Functions + Firestore cache avantajları (sunucu tarafı merkezi cache/izleme) bu modda yoktur.
- İleride ihtiyaç artarsa tekrar backend cache katmanına geçilebilir.
