# Firebase Cloud Functions - Dijital Dini Takvim

Bu dizin, Diyanet Awqat Salah API'den veri çekip Firebase Firestore'a kaydeden Cloud Functions kodlarını içerir.

## 📋 Genel Bakış

**Amaç**: Diyanet API'nin rate limit kısıtlamalarını (5 istek/gün) aşmak için Firebase Firestore'u caching layer olarak kullanmak. Bu sayede 100,000+ kullanıcı aynı anda uygulamayı kullanabilir.

**Mimari**:
```
[Diyanet API] 
    ↓ (Günde 1 kez - Cloud Function)
[Firebase Firestore]
    ↓ (Sınırsız okuma)
[Mobil Uygulama - 100K+ kullanıcı]
```

## 🔥 Cloud Functions

### 1. `dailyDiyanetSync` (Scheduled)
- **Çalışma Zamanı**: Her gün saat 00:00 (Türkiye saati)
- **Görev**: 
  - Diyanet API'ye authenticate ol
  - Bugün ve yarın için veri çek:
    - Namaz vakitleri (tüm şehirler için)
    - Hicri takvim
    - Günlük içerik (Ayet, Hadis, Dua)
    - Dini günler (yıllık)
    - Kıble yönü (henüz cache'lenmemişse)
  - Firestore'a kaydet

### 2. `manualDiyanetSync` (HTTP)
- **Kullanım**: Manuel test için
- **URL**: `https://REGION-PROJECT_ID.cloudfunctions.net/manualDiyanetSync`
- **Method**: GET

## 📦 Firestore Collections

### `prayer_times/{cityCode}_{date}`
```javascript
{
  "cityCode": "9541",
  "cityName": "İstanbul",
  "date": "2025-01-15",
  "fajr": "06:45",
  "sunrise": "08:15",
  "dhuhr": "13:05",
  "asr": "15:35",
  "maghrib": "17:50",
  "isha": "19:20",
  "lastUpdated": Timestamp
}
```

### `hijri_calendar/{date}`
```javascript
{
  "date": "2025-01-15",
  "hijriDay": "15",
  "hijriMonth": "Rajab",
  "hijriYear": "1446",
  "lastUpdated": Timestamp
}
```

### `daily_content/{date}`
```javascript
{
  "date": "2025-01-15",
  "ayet": {
    "text": "...",
    "surah": "...",
    "verse": "..."
  },
  "hadis": {
    "text": "...",
    "source": "..."
  },
  "dua": {
    "text": "...",
    "arabic": "..."
  },
  "lastUpdated": Timestamp
}
```

### `religious_days/{year}`
```javascript
{
  "year": 2025,
  "days": [
    {
      "name": "Regaib Kandili",
      "date": "2025-02-13",
      "description": "..."
    },
    // ...
  ],
  "lastUpdated": Timestamp
}
```

### `qibla/{cityCode}`
```javascript
{
  "cityCode": "9541",
  "cityName": "İstanbul",
  "angle": 157.5,
  "lastUpdated": Timestamp
}
```

## 🚀 Kurulum

### 1. Firebase CLI Kurulumu
```bash
npm install -g firebase-tools
```

### 2. Firebase Login
```bash
firebase login
```

### 3. Firebase Projesi Başlatma
```bash
# Proje kök dizininde
firebase init functions

# Seçenekler:
# - JavaScript kullan
# - ESLint evet
# - Dependencies şimdi yükle
```

### 4. Dependencies Yükleme
```bash
cd functions
npm install
```

### 5. Deploy
```bash
firebase deploy --only functions
```

## ⚙️ Konfigürasyon

### Türk Şehirleri Listesi
`index.js` dosyasındaki `TURKISH_CITIES` array'ini güncelleyerek daha fazla şehir ekleyebilirsiniz:

```javascript
const TURKISH_CITIES = [
  {countryCode: "2", stateCode: "2", cityCode: "9541", name: "İstanbul"},
  {countryCode: "2", stateCode: "2", cityCode: "9559", name: "Ankara"},
  // Daha fazla şehir ekleyin...
];
```

### Diyanet API Credentials
Credentials `index.js` dosyasında hardcoded. Production için Firebase Secret Manager kullanın:

```bash
firebase functions:secrets:set DIYANET_EMAIL
firebase functions:secrets:set DIYANET_PASSWORD
```

Sonra kodda kullanın:
```javascript
const DIYANET_EMAIL = process.env.DIYANET_EMAIL;
const DIYANET_PASSWORD = process.env.DIYANET_PASSWORD;
```

## 📊 Rate Limit Yönetimi

Diyanet API rate limits:
- **Daily endpoint**: 5 istek/gün (her parametre kombinasyonu için)
- **DateRange endpoint**: 10 istek/ay
- **İlk 15 gün**: 100 istek limit

Bu function ile:
- Günlük sadece **1 kez** API'ye istek atıyoruz
- Tüm şehirler için veri çekiyoruz (~10 şehir = 10 istek)
- Rate limit içinde kalıyoruz ✅
- 100,000+ kullanıcı Firestore'dan okur (sınırsız) ✅

## 🧪 Test

### Lokal Test (Emulator)
```bash
cd functions
npm run serve
```

### Manuel Trigger
Firebase Console'da:
1. Functions → manualDiyanetSync
2. "Test function" tıkla
3. Logs'u kontrol et

Veya curl ile:
```bash
curl https://REGION-PROJECT_ID.cloudfunctions.net/manualDiyanetSync
```

## 📝 Logs

```bash
# Tüm logs
firebase functions:log

# Spesifik function logs
firebase functions:log --only dailyDiyanetSync
```

## 🔒 Güvenlik

### Firestore Security Rules
`firestore.rules` dosyasında:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Prayer times - read only for authenticated users
    match /prayer_times/{document=**} {
      allow read: if request.auth != null;
      allow write: if false; // Only Cloud Functions can write
    }
    
    match /hijri_calendar/{document=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    match /daily_content/{document=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    match /religious_days/{document=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    match /qibla/{document=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    // Metadata - internal use only
    match /_metadata/{document=**} {
      allow read, write: if false;
    }
  }
}
```

## 💰 Maliyet Tahmini

Firebase Spark (Free) Plan:
- Cloud Functions: 2M invocations/month
- Firestore: 50K reads/day, 20K writes/day
- Bu uygulama için: **ÜCRETSİZ** ✅

Blaze (Pay-as-you-go) Plan:
- Günlük 1 scheduled function çalışması
- ~20 API request/gün (tüm şehirler)
- 100K kullanıcı x günde 5 okuma = 500K Firestore read/gün
- Tahmini maliyet: **~$5-10/ay**

## 🐛 Troubleshooting

### "Authentication failed"
- Email/password doğru mu kontrol edin
- Diyanet hesabı aktif mi kontrol edin

### "Rate limit exceeded"
- Çok fazla şehir mi eklendi?
- Scheduled function saati değiştirildi mi?
- Logs'u kontrol edin: `firebase functions:log`

### "Function timeout"
- Default timeout 60 saniye
- `index.js` içinde timeout artırın:
```javascript
exports.dailyDiyanetSync = functions
  .runWith({timeoutSeconds: 300}) // 5 dakika
  .pubsub.schedule(...)
```

## 📚 İlgili Dökümanlar

- [Firebase Cloud Functions Docs](https://firebase.google.com/docs/functions)
- [Cloud Scheduler Docs](https://firebase.google.com/docs/functions/schedule-functions)
- [Diyanet Awqat Salah API](https://github.com/malikmasis/DiyanetAwqatSalah)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)

## 📞 Destek

Sorun yaşarsanız:
1. Logs kontrol edin: `firebase functions:log`
2. Firebase Console'da Functions status kontrol edin
3. GitHub issue açın
