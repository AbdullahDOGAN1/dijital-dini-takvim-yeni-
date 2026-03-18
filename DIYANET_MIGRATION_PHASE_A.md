# Diyanet Migration – Faz A (Tek Kaynak Kilidi)

Tarih: 18 Mart 2026

## Amaç
Uygulamada veri kaynağını tekilleştirip (Diyanet Awqat Salah + Firestore), legacy ve dağınık fallback yollarını kontrollü biçimde kaldırmak.

## Bu adımda yapılan
- `lib/services/religious_days_service.dart` legacy `DiyanetApiService` bağımlılığından çıkarıldı.
- Aynı servis, artık `DiyanetAwqatSalahService.getReligiousDays(year)` ile çalışacak şekilde geçirildi.
- API response -> `ReligiousDay` dönüşümü servis içine eklendi.
- Geçici güvenlik için statik fallback korunmuştur (tam kaldırma Faz C’de).

## Kritik bulgular (Faz A envanteri)
1. `religious_days_service.dart` artık Awqat'a bağlı, ancak static fallback hâlâ mevcut.
2. `religious_events_service_fixed.dart` içinde hâlâ JSON fallback + detay JSON yükleme var.
3. `prayer_api_service.dart` içinde DateRange başarısızlığında günlük endpoint + varsayılan saat fallback akışı mevcut.
4. `functions/index.js` yalnızca 8 şehir sync ediyor; aylık modelde tüm Türkiye kapsamı yok.
5. `functions/index.js` sadece `currentDate` sync ediyor; aylık modelde güncel veri doğruluğu operasyonel risk taşıyor.

## Faz A tamamlanma kriterleri
- [ ] Dini günler/geceler için legacy servis kullanımı tamamen kaldırılmış olacak.
- [ ] `diyanet_api_service.dart` referanssız kalacak (sonraki fazda silinecek).
- [ ] Ekranlar tek akıştan veri alacak (Awqat/Firestore), dağınık JSON fallback minimuma inecek.
- [ ] Kullanılan endpointlerin tek bir kaynak dokümanı olacak.

## Faz B’ye geçiş için sıradaki teknik işler
1. `functions/index.js` şehir listesini 81 ile genişlet.
2. Aylık run’da veri bütünlüğü kontrolü ekle (`_metadata` + kapsam doğrulama).
3. Firestore yazımında idempotent alanları netleştir (mevcut merge korunacak).
4. GitHub Action run başarısızlık görünürlüğünü artır (response body + status).

## Not
Ürün kararı gereği sync modeli aylık tek job olarak kalır. Stale-data riski kabul edilmiş operasyonel risk olarak izlenecektir.
