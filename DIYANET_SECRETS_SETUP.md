# Diyanet Secrets Setup (No Blaze)

Bu repo artık Firebase deploy gerektirmeyen JSON-cache mimarisiyle çalışır.

## 1) GitHub Actions Secrets

Repository > Settings > Secrets and variables > Actions bölümüne ekleyin:

- `DIYANET_EMAIL`
- `DIYANET_PASSWORD`

Bu secretlar `Diyanet Monthly JSON Sync (No Blaze)` workflow'unda kullanılır.

## 2) Workflow

İlk doldurma için workflow'u elle çalıştırın:

- Actions -> `Diyanet Monthly JSON Sync (No Blaze)` -> `Run workflow`

Workflow başarılı olduğunda repo içindeki şu dosyalar güncellenir:

- `assets/data/diyanet_cache/prayer_times_window.json`
- `assets/data/diyanet_cache/religious_days_<year>.json`
- `assets/data/diyanet_cache/sync_status.json`

## 3) Mobil Uygulama

Mobil uygulama varsayılan olarak bu JSON cache'i okur. Ek secret gerekmez.

Opsiyonel test amaçlı farklı bir cache URL'i için:

```powershell
flutter run --dart-define=DIYANET_CACHE_BASE_URL=https://raw.githubusercontent.com/<owner>/<repo>/<branch>/assets/data/diyanet_cache
```

## 4) Güvenlik Notu

- Diyanet kimlik bilgilerini repo içine veya kod dosyalarına yazmayın.
- Secret rotation sonrası workflow'u tekrar çalıştırıp yeni veriyi üretin.
