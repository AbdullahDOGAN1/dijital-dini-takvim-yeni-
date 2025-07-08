import '../models/religious_day_model.dart';
import 'diyanet_api_service.dart';

class ReligiousDaysService {
  static final DiyanetApiService _diyanetService = DiyanetApiService();
  static List<ReligiousDay>? _cachedReligiousDays;
  static int? _cachedYear;

  /// Dini günleri al - önce Diyanet API'sini dene, başarısız olursa statik veri kullan
  static Future<List<ReligiousDay>> getReligiousDays([int? year]) async {
    final targetYear = year ?? DateTime.now().year;
    
    // Cache kontrol et
    if (_cachedReligiousDays != null && _cachedYear == targetYear) {
      return _cachedReligiousDays!;
    }

    try {
      // Diyanet API'sinden güncel veriyi al
      final apiData = await _diyanetService.fetchReligiousDaysFromDiyanet(year: targetYear);
      
      if (apiData.isNotEmpty) {
        _cachedReligiousDays = apiData;
        _cachedYear = targetYear;
        return apiData;
      }
    } catch (e) {
      print('Diyanet API\'den veri alınamadı: $e');
    }

    // API başarısız olursa statik veriyi kullan
    final staticData = getReligiousDays2025();
    _cachedReligiousDays = staticData;
    _cachedYear = targetYear;
    return staticData;
  }

  /// Cache'i temizle
  static void clearCache() {
    _cachedReligiousDays = null;
    _cachedYear = null;
  }

  /// Statik veri (fallback)
  static List<ReligiousDay> getReligiousDays2025() {
    return [
      // 2025 DOĞRU TARİHLER
      
      // KANDİLLER (Geçmişten başlayarak)
      ReligiousDay(
        name: 'Regaib Kandili',
        date: DateTime(2025, 1, 3),
        hijriDate: '1 Recep 1446',
        category: 'kandil',
        description: 'Recep ayının ilk Cuma gecesi olan Regaib Kandili, üç ayların başlangıcını müjdeleyen mübarek gecedir.',
        importance: 'Bu gece, Allah\'ın rahmetinin bol olduğu, duaların kabul edildiği ve günahların affedildiği özel gecelerden biridir.',
        traditions: [
          'Oruç tutma',
          'Gece ibadeti',
          'Kur\'an okuma',
          'Dua etme',
          'Sadaka verme'
        ],
        prayers: [
          'Regaib namazı',
          'Tesbih ve zikir',
          'İstiğfar',
          'Salat-ı tefriciye'
        ],
      ),

      ReligiousDay(
        name: 'Mirac Kandili',
        date: DateTime(2025, 1, 27),
        hijriDate: '27 Recep 1446',
        category: 'kandil',
        description: 'Hz. Muhammed\'in (s.a.v.) Mekke\'den Kudüs\'e, oradan da göklere yükseldiği mübarek gece olan Mirac Kandili.',
        importance: 'Bu gecede Hz. Peygamber\'e beş vakit namaz farz kılındı ve bu gece İslam\'ın en önemli ibadetlerinden birinin başlangıcı oldu.',
        traditions: [
          'Mirac hadisesi anlatılır',
          'Gece ibadeti yapılır',
          'Namaza özel önem verilir',
          'Dua edilir',
          'Sadaka verilir'
        ],
        prayers: [
          'Beş vakit namaz',
          'Gece namazı',
          'Kur\'an okuma',
          'Mirac duası'
        ],
      ),

      ReligiousDay(
        name: 'Berat Kandili',
        date: DateTime(2025, 2, 12),
        hijriDate: '15 Şaban 1446',
        category: 'kandil',
        description: 'Şaban ayının 15. gecesi olan Berat Kandili, bağışlanma ve beraat gecesi olarak bilinir.',
        importance: 'Bu gecede kulların bir sonraki yıla ait kaderleri belirlenir, rizıklar takdir edilir ve ömürler yazılır.',
        traditions: [
          'Gece boyu ibadet',
          'Mezar ziyareti',
          'Sadaka verme',
          'Halva dağıtma',
          'Komşularla paylaşım'
        ],
        prayers: [
          'Gece namazı',
          'Kur\'an hatmi',
          'İstiğfar',
          'Berat duası'
        ],
      ),

      ReligiousDay(
        name: 'Kadir Gecesi',
        date: DateTime(2025, 3, 26),
        hijriDate: '27 Ramazan 1446',
        category: 'kandil',
        description: 'Kur\'an\'ın indirilmeye başlandığı gece olan Kadir Gecesi, bin aydan daha hayırlı olan mübarek gecedir.',
        importance: 'Bu gece yapılan ibadetler bin aydan daha değerlidir. Allah\'ın rahmet ve mağfireti bu gecede zirvesindedir.',
        traditions: [
          'Gece boyu uyanık kalma',
          'Kur\'an okuma',
          'Dua etme',
          'İbadet etme',
          'Sadaka verme'
        ],
        prayers: [
          'Gece namazı',
          'Kur\'an okuma',
          'İstiğfar',
          'Kadir gecesi duası'
        ],
      ),

      ReligiousDay(
        name: 'Mevlid Kandili',
        date: DateTime(2025, 8, 5),
        hijriDate: '12 Rebiülevvel 1447',
        category: 'kandil',
        description: 'Hz. Muhammed\'in (s.a.v.) doğum günü olan Mevlid Kandili, İslam aleminde büyük bir sevinçle kutlanan mübarek gecelerden biridir.',
        importance: 'Bu gece, Hz. Peygamber\'in hayatı hatırlanır, onun güzel ahlakı ve öğretileri anılır.',
        traditions: [
          'Mevlid okuma',
          'Dua etme',
          'Sadaka verme',
          'Hz. Peygamber\'i anma',
          'Camide toplu ibadet'
        ],
        prayers: [
          'Salavat getirme',
          'İstiğfar',
          'Kur\'an okuma',
          'Mevlid duası'
        ],
      ),

      // BAYRAMLAR
      ReligiousDay(
        name: 'Ramazan Bayramı',
        date: DateTime(2025, 3, 30),
        hijriDate: '1 Şevval 1446',
        category: 'bayram',
        description: 'Ramazan ayının sona ermesiyle kutlanan İd-i Fıtr, müslümanların en büyük bayramlarından biridir.',
        importance: 'Bu bayram, bir aylık oruç ibadetinin tamamlanmasının sevinci ve Allah\'a şükrün ifadesidir.',
        traditions: [
          'Bayram namazı',
          'Bayram ziyaretleri',
          'Bayramlık giyme',
          'Çocuklara harçlık verme',
          'Fıtır sadakası'
        ],
        prayers: [
          'Bayram namazı',
          'Bayram tekbirleri',
          'Şükür duaları'
        ],
      ),

      ReligiousDay(
        name: 'Kurban Bayramı',
        date: DateTime(2025, 6, 6),
        hijriDate: '10 Zilhicce 1446',
        category: 'bayram',
        description: 'Hz. İbrahim\'in Allah\'a olan teslimiyetini anma günü olan Kurban Bayramı, İslam\'ın en büyük bayramıdır.',
        importance: 'Bu bayram, sadakat, teslimiyet ve paylaşmanın sembolüdür. Kurban kesilir ve ihtiyaç sahipleriyle paylaşılır.',
        traditions: [
          'Kurban kesme',
          'Bayram namazı',
          'Bayram ziyaretleri',
          'Et dağıtma',
          'Hac ibadeti'
        ],
        prayers: [
          'Bayram namazı',
          'Kurban duası',
          'Bayram tekbirleri'
        ],
      ),

      // ÖZEL GÜNLER
      ReligiousDay(
        name: 'Ramazan Başlangıcı',
        date: DateTime(2025, 2, 28),
        hijriDate: '1 Ramazan 1446',
        category: 'ozel_gun',
        description: 'Mübarek Ramazan ayının başlangıcı. Müslümanlar bu ayda oruç tutarak manevi olgunluğa ulaşmaya çalışırlar.',
        importance: 'Ramazan, İslam\'ın beş şartından biri olan orucun farz kılındığı mübarek aydır.',
        traditions: [
          'Sahur yemeği',
          'İftar yapma',
          'Teravih namazı',
          'Kur\'an okuma',
          'Sadaka verme'
        ],
        prayers: [
          'Sahur duası',
          'İftar duası',
          'Teravih namazı',
          'Gece namazı'
        ],
      ),

      ReligiousDay(
        name: 'Arefe Günü',
        date: DateTime(2025, 6, 5),
        hijriDate: '9 Zilhicce 1446',
        category: 'ozel_gun',
        description: 'Kurban Bayramı\'nın arifesi olan Arefe günü, hacıların Arefe dağında vakfe yaptıkları mübarek gündür.',
        importance: 'Bu gün oruç tutmanın büyük sevabı vardır. Önceki ve sonraki yılın günahlarını örttüğüne inanılır.',
        traditions: [
          'Oruç tutma',
          'Dua etme',
          'İbadet yapma',
          'Sadaka verme',
          'Hac ibadeti'
        ],
        prayers: [
          'Arefe duası',
          'İstiğfar',
          'Kur\'an okuma'
        ],
      ),

      ReligiousDay(
        name: 'Aşure Günü',
        date: DateTime(2025, 7, 15),
        hijriDate: '10 Muharrem 1447',
        category: 'ozel_gun',
        description: 'Muharrem ayının 10. günü olan Aşure günü, birçok kutsal olayın yaşandığı mübarek gündür.',
        importance: 'Bu günde Hz. Nuh\'un gemisi karaya oturdu, Hz. Musa kavmiyle birlikte denizi geçti ve daha nice mucizeler gerçekleşti.',
        traditions: [
          'Aşure tatlısı pişirme',
          'Komşularla paylaşım',
          'Oruç tutma',
          'Sadaka verme',
          'Dua etme'
        ],
        prayers: [
          'Şükür duaları',
          'İstiğfar',
          'Aşure duası'
        ],
      ),

      ReligiousDay(
        name: 'Hicri Yılbaşı',
        date: DateTime(2025, 6, 27),
        hijriDate: '1 Muharrem 1447',
        category: 'ozel_gun',
        description: 'İslam takviminin başlangıcı olan Hicri Yılbaşı, Hz. Muhammed\'in Medine\'ye hicretini anma günüdür.',
        importance: 'Hicret, İslam tarihinin dönüm noktalarından biridir.',
        traditions: [
          'Hicret hadisesi anlatılır',
          'Dua edilir',
          'İbadet yapılır',
          'Sadaka verilir'
        ],
        prayers: [
          'Şükür duaları',
          'İstiğfar',
          'Hicret duası'
        ],
      ),
    ];
  }

  /// Yaklaşan dini günleri al
  static Future<List<ReligiousDay>> getUpcomingDays([int? year]) async {
    final allDays = await getReligiousDays(year);
    final now = DateTime.now();
    
    return allDays.where((day) => day.date.isAfter(now)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Bugünün dini günlerini al
  static Future<List<ReligiousDay>> getTodaysDays([int? year]) async {
    final allDays = await getReligiousDays(year);
    
    return allDays.where((day) => day.isToday).toList();
  }

  /// Kategoriye göre dini günleri al
  static Future<List<ReligiousDay>> getDaysByCategory(String category, [int? year]) async {
    final allDays = await getReligiousDays(year);
    return allDays.where((day) => day.category == category).toList();
  }

  /// Bir sonraki dini günü al
  static Future<ReligiousDay?> getNextReligiousDay([int? year]) async {
    final upcoming = await getUpcomingDays(year);
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  /// Diyanet API'sinden gelecek dini günü al
  static Future<Map<String, dynamic>?> getNextReligiousDayWithCountdown() async {
    return await _diyanetService.getNextReligiousDay();
  }

  /// Kategori listesi
  static List<String> getCategories() {
    return ['kandil', 'bayram', 'ozel_gun'];
  }

  /// Kategori görünen adları
  static Map<String, String> getCategoryDisplayNames() {
    return {
      'kandil': 'Kandiller',
      'bayram': 'Bayramlar',
      'ozel_gun': 'Özel Günler',
    };
  }
}