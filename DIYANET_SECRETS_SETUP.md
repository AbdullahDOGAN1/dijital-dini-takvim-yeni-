# Diyanet Secrets Setup

Bu dosya, Diyanet API kimlik bilgilerini güvenli şekilde yapılandırmak için gereken adımları içerir.

## 1) Flutter App (local/dev)

Diyanet bilgilerini kod içine yazmayın. Uygulamayı aşağıdaki `dart-define` parametreleriyle çalıştırın:

```powershell
flutter run -d emulator-5554 --dart-define=DIYANET_EMAIL=YOUR_EMAIL --dart-define=DIYANET_PASSWORD=YOUR_PASSWORD
```

## 2) Firebase Functions Secrets

Cloud Functions ortamına secretları ekleyin:

```powershell
firebase functions:secrets:set DIYANET_EMAIL
firebase functions:secrets:set DIYANET_PASSWORD
firebase functions:secrets:set SYNC_API_TOKEN
```

Alternatif (runtime config) yöntem:

```powershell
firebase functions:config:set diyanet.email="YOUR_EMAIL" diyanet.password="YOUR_PASSWORD" sync.token="YOUR_SYNC_TOKEN"
```

Sonrasında deploy:

```powershell
cd functions
npm install
firebase deploy --only functions
```

## 3) GitHub Actions Secrets

Repository > Settings > Secrets and variables > Actions bölümünde şu secretları ekleyin:

- `DIYANET_SYNC_URL`: Deploy sonrası `manualDiyanetSync` endpoint URL
- `DIYANET_SYNC_TOKEN`: `SYNC_API_TOKEN` ile aynı değer

Opsiyonel olarak dokümantasyon amaçlı aşağıdakileri de saklayabilirsiniz (workflow şu an kullanmıyor):
- `DIYANET_EMAIL`
- `DIYANET_PASSWORD`

## 4) Güvenlik Notu

- `DIYANET_EMAIL` ve `DIYANET_PASSWORD` değerlerini repo içinde hiçbir dosyaya yazmayın.
- `SYNC_API_TOKEN` manuel sync endpoint’ini korumak için gereklidir.
- Secret rotation yaparken Firebase + GitHub tarafını birlikte güncelleyin.
