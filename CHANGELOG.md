# Changelog

Bu dosya, projede yapılan önemli teknik değişikliklerin kısa özetini içerir.

Bu format semver sürümlemeye göre tutulur.

## [Unreleased]

- Henüz yayınlanmamış değişiklik yok.

## [1.1.0] - 2026-03-18

### Added
- `lib/services/prayer_api_service.dart` içinde Firestore cache-first akışı güçlendirildi.
- Bildirim akışı merkezi servis üzerinden çalışacak şekilde güncellendi (`NotificationServiceFixed` → `PrayerApiService`).
- `pubspec.yaml` içine `just_audio`, `flutter_staggered_animations` ve `percent_indicator` bağımlılıkları eklendi.
- Kapsamlı kalite/temizlik turu sonrası proje genelinde analiz ve test doğrulaması yapıldı.

### Changed
- `withOpacity` kullanımları geniş ölçekte `withValues(alpha: ...)` formatına taşındı.
- Async sonrası `BuildContext` kullanım noktalarına güvenli `mounted/context.mounted` kontrolleri eklendi.
- Eski test dosyaları mevcut proje yapısına uyumlu hale getirildi (import yolları, semboller, ekran adları).

### Removed
- Kullanılmayan legacy servis zinciri ve artık referanslanmayan dosyalar kaldırıldı.
- Eski ve kırık ekran/widget kopyaları temizlendi.

### Validation
- `flutter analyze lib` → temiz
- `flutter analyze` → temiz
- `runTests` → geçen
