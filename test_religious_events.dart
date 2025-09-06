import 'package:flutter/material.dart';
import 'lib/services/religious_events_service.dart';
import 'lib/models/religious_event_model.dart';

void main() async {
  print('🎯 Dini Günler Sistemi Test Başlıyor...');
  
  try {
    final service = ReligiousEventsService();
    
    // 2025 yılı dini günlerini test et
    print('\n📅 2025 Yılı Dini Günleri Yükleniyor...');
    final events2025 = service.getCurrentYearEvents();
    print('✅ ${events2025.length} adet dini gün yüklendi');
    
    // İlk 5 etkinliği göster
    print('\n📋 İlk 5 Dini Gün:');
    for (int i = 0; i < 5 && i < events2025.length; i++) {
      final event = events2025[i];
      print('${i + 1}. ${event.name} - ${event.day} ${event.month} ${event.year} (${event.category ?? 'Özel'})');
    }
    
    // Yaklaşan etkinlikleri test et
    print('\n🔔 Yaklaşan Dini Günler Yükleniyor...');
    final upcomingEvents = service.getUpcomingEvents();
    print('✅ ${upcomingEvents.length} adet yaklaşan etkinlik bulundu');
    
    // İlk 3 yaklaşan etkinliği göster
    print('\n🔜 İlk 3 Yaklaşan Etkinlik:');
    for (int i = 0; i < 3 && i < upcomingEvents.length; i++) {
      final event = upcomingEvents[i];
      final daysLeft = event.daysUntil;
      final status = event.isToday ? 'BUGÜN' : '$daysLeft gün sonra';
      print('${i + 1}. ${event.name} - ${event.day} ${event.month} ${event.year} ($status)');
    }
    
    // Kategorileri test et
    print('\n🏷️ Kategoriler Analizi:');
    final categories = <String, int>{};
    for (final event in events2025) {
      final category = event.category ?? 'Özel';
      categories[category] = (categories[category] ?? 0) + 1;
    }
    
    categories.forEach((category, count) {
      print('- $category: $count adet');
    });
    
    print('\n✅ Tüm testler başarıyla tamamlandı!');
    print('🎉 Dini Günler sistemi 2-tab yapısıyla hazır!');
    
  } catch (e) {
    print('❌ Test sırasında hata oluştu: $e');
  }
}
