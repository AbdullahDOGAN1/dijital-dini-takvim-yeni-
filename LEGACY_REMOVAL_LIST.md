# Legacy Removal List (Güvenli Kaldırma Adayları)

Tarih: 18 Mart 2026

Bu liste, workspace genelinde (lib + test) import/usage taramasına göre hazırlanmıştır.

## Güvenle kaldırılabilir (referans yok)

Aşağıdaki dosyaların aktif kodda import veya sınıf kullanımı bulunmuyor:

- `lib/services/aladhan_api_service.dart`
- `lib/services/optimized_aladhan_api_service.dart`
- `lib/services/diyanet_prayer_service.dart`
- `lib/services/api_rate_limiter.dart` *(yalnızca `optimized_aladhan_api_service.dart` tarafından import ediliyordu)*
- `lib/services/prayer_cache_service.dart` *(yalnızca `optimized_aladhan_api_service.dart` tarafından import ediliyordu)*
- `lib/services/prayer_times_manager.dart`
- `lib/services/firebase_service.dart`
- `lib/config/firebase_config.dart`

## Tutulmalı (aktif kullanım var)

- `lib/services/prayer_api_service.dart` (aktif ekran/widget/bildirim akışı)
- `lib/services/daily_content_service.dart` (takvim + günlük içerik)
- `lib/services/notification_service_fixed.dart` (bildirim ayarları + scheduler)
- `lib/services/religious_days_service.dart` (religious days ekranı)
- `lib/services/diyanet_json_cache_service.dart` (JSON cache-first akış)
- `lib/services/religious_events_service_fixed.dart` (religious events ekranları)

## Kaldırma sırası (öneri)

1. Önce AlAdhan zincirini kaldır:
   - `aladhan_api_service.dart`
   - `optimized_aladhan_api_service.dart`
   - `api_rate_limiter.dart`
   - `prayer_cache_service.dart`
   - `diyanet_prayer_service.dart`

2. Sonra kullanılmayan Firebase yardımcılarını kaldır:
   - `prayer_times_manager.dart`
   - `firebase_service.dart`
   - `firebase_config.dart`

3. Her blok sonrası hızlı doğrulama:
   - `get_errors` ile hata taraması
   - gerekli ise `flutter analyze`
