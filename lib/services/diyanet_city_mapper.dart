/// Diyanet API City Code Mapper
/// 
/// Maps Turkish city names to Diyanet API city codes
/// Türkiye için: CountryCode: "2", StateCode: "2"
class DiyanetCityMapper {
  // Türkiye için sabit kodlar
  static const String countryCode = '2';
  static const String stateCode = '2';

  // Şehir isimlerinden Diyanet API city code'larına mapping
  // Bu kodlar functions/index.js'den alındı ve genişletilebilir
  static const Map<String, String> cityCodeMap = {
    'İstanbul': '9541',
    'Ankara': '9559',
    'İzmir': '9552',
    'Bursa': '9479',
    'Adana': '9496',
    'Gaziantep': '9522',
    'Konya': '9557',
    'Antalya': '9497',
    // Daha fazla şehir eklenebilir - API'den çekilebilir
    'Adıyaman': '9158',
    'Afyonkarahisar': '9167',
    'Ağrı': '9185',
    'Amasya': '9198',
    'Artvin': '9246',
    'Aydın': '9252',
    'Balıkesir': '9270',
    'Bilecik': '9297',
    'Bingöl': '9303',
    'Bitlis': '9311',
    'Bolu': '9315',
    'Burdur': '9327',
    'Çanakkale': '9352',
    'Çankırı': '9359',
    'Çorum': '9370',
    'Denizli': '9392',
    'Diyarbakır': '9402',
    'Edirne': '9419',
    'Elazığ': '9432',
    'Erzincan': '9440',
    'Erzurum': '9451',
    'Eskişehir': '9470',
    'Giresun': '9486',
    'Gümüşhane': '9489',
    'Hakkari': '9492',
    'Hakkâri': '9492',
    'Hatay': '9498',
    'Isparta': '9528',
    'İsparta': '9528',
    'Kars': '9594',
    'Kastamonu': '9609',
    'Kayseri': '9620',
    'Kırklareli': '9629',
    'Kırşehir': '9635',
    'Kocaeli': '9654',
    'Kütahya': '9689',
    'Malatya': '9701',
    'Manisa': '9708',
    'Kahramanmaraş': '9716',
    'Mardin': '9726',
    'Muğla': '9731',
    'Muş': '9747',
    'Nevşehir': '9754',
    'Niğde': '9760',
    'Ordu': '9766',
    'Rize': '9784',
    'Sakarya': '9789',
    'Samsun': '9797',
    'Siirt': '9807',
    'Sinop': '9819',
    'Sivas': '9829',
    'Tekirdağ': '9849',
    'Tokat': '9862',
    'Trabzon': '9879',
    'Tunceli': '9887',
    'Şanlıurfa': '9898',
    'Uşak': '9905',
    'Van': '9911',
    'Yozgat': '9919',
    'Zonguldak': '9930',
    'Aksaray': '9935',
    'Bayburt': '9940',
    'Karaman': '9945',
    'Kırıkkale': '9950',
    'Batman': '9955',
    'Şırnak': '9960',
    'Bartın': '9965',
    'Ardahan': '9970',
    'Iğdır': '9975',
    'Yalova': '9980',
    'Karabük': '9985',
    'Kilis': '9990',
    'Osmaniye': '9995',
    'Düzce': '10000',
    'Mersin': '9516', // İçel olarak da bilinir
    'İçel': '9516',
  };

  /// Get city code for a city name
  /// Returns null if city not found
  static String? getCityCode(String cityName) {
    return cityCodeMap[cityName];
  }

  /// Check if city is supported
  static bool isCitySupported(String cityName) {
    return cityCodeMap.containsKey(cityName);
  }

  /// Get all supported cities
  static List<String> getSupportedCities() {
    return cityCodeMap.keys.toList()..sort();
  }

  /// Get default city (Ankara) code
  static String getDefaultCityCode() {
    return cityCodeMap['Ankara']!;
  }
}
