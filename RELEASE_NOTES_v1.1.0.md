# Dijital Dini Takvim v1.1.0

Yayın tarihi: 18 Mart 2026

## Öne Çıkanlar
- Diyanet veri akışı için cache-first mimari güçlendirildi.
- Bildirim zamanlama akışı merkezi servis üzerinden sadeleştirildi.
- Uygulama genelinde kapsamlı kalite ve temizlik çalışması yapıldı.
- Proje genelinde analiz temiz duruma getirildi.

## Added
- Diyanet + Firebase odaklı senkronizasyon altyapısı eklendi.
- Gerekli yeni bağımlılıklar eklendi:
  - just_audio
  - flutter_staggered_animations
  - percent_indicator
- Operasyon/test için rehber ve script dosyaları eklendi.

## Changed
- Geniş ölçekte withOpacity kullanımları withValues(alpha: ...) formatına taşındı.
- Async sonrası BuildContext kullanım noktalarına mounted/context.mounted kontrolleri eklendi.
- Test dosyaları mevcut proje yapısıyla uyumlu hale getirildi.

## Removed
- Kullanılmayan legacy servis zinciri ve referanslanmayan eski ekran/widget dosyaları kaldırıldı.
- Eski/bozuk bazı test ve yardımcı dosyalar temizlendi.

## Validation
- flutter analyze lib: temiz
- flutter analyze: temiz
- test çalıştırmaları: geçen

## Not
Bu sürüm, teknik borç azaltma + mimari sadeleştirme + release hazırlığı odaklı stabilizasyon sürümüdür.
