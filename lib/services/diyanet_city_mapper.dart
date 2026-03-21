/// Diyanet API City Code Mapper
///
/// Maps Turkish city names to Diyanet API city codes
/// Türkiye için: CountryCode: "2", StateCode: "2"
class DiyanetCityMapper {
  static const String countryCode = '2';
  static const String stateCode = '2';

  static const Map<String, String> cityCodeMap = {
    'Adana': '9146',
    'Adıyaman': '9158',
    'Afyonkarahisar': '9167',
    'Ağrı': '9185',
    'Aksaray': '9193',
    'Amasya': '9198',
    'Ankara': '9206',
    'Antalya': '9225',
    'Ardahan': '9238',
    'Artvin': '9246',
    'Aydın': '9252',
    'Balıkesir': '9270',
    'Bartın': '9285',
    'Batman': '9288',
    'Bayburt': '9295',
    'Bilecik': '9297',
    'Bingöl': '9303',
    'Bitlis': '9311',
    'Bolu': '9315',
    'Burdur': '9327',
    'Bursa': '9335',
    'Çanakkale': '9352',
    'Çankırı': '9359',
    'Çorum': '9370',
    'Denizli': '9392',
    'Diyarbakır': '9402',
    'Düzce': '9414',
    'Edirne': '9419',
    'Elazığ': '9432',
    'Erzincan': '9440',
    'Erzurum': '9451',
    'Eskişehir': '9470',
    'Gaziantep': '9479',
    'Giresun': '9494',
    'Gümüşhane': '9501',
    'Hakkari': '9507',
    'Hatay': '20089',
    'Iğdır': '9522',
    'Isparta': '9528',
    'İstanbul': '9541',
    'İzmir': '9560',
    'Kahramanmaraş': '9577',
    'Karabük': '9581',
    'Karaman': '9587',
    'Kars': '9594',
    'Kastamonu': '9609',
    'Kayseri': '9620',
    'Kırıkkale': '9635',
    'Kırklareli': '9638',
    'Kırşehir': '9646',
    'Kilis': '9629',
    'Kocaeli': '9654',
    'Konya': '9676',
    'Kütahya': '9689',
    'Malatya': '9703',
    'Manisa': '9716',
    'Mardin': '9726',
    'Mersin': '9737',
    'Muğla': '9747',
    'Muş': '9755',
    'Nevşehir': '9760',
    'Niğde': '9766',
    'Ordu': '9782',
    'Osmaniye': '9788',
    'Rize': '9799',
    'Sakarya': '9807',
    'Samsun': '9819',
    'Siirt': '9839',
    'Sinop': '9847',
    'Sivas': '9868',
    'Şanlıurfa': '9831',
    'Şırnak': '9854',
    'Tekirdağ': '9879',
    'Tokat': '9887',
    'Trabzon': '9905',
    'Tunceli': '9914',
    'Uşak': '9919',
    'Van': '9930',
    'Yalova': '9935',
    'Yozgat': '9949',
    'Zonguldak': '9955',
  };

  static String? getCityCode(String cityName) {
    return cityCodeMap[cityName];
  }

  static bool isCitySupported(String cityName) {
    return cityCodeMap.containsKey(cityName);
  }

  static List<String> getSupportedCities() {
    return cityCodeMap.keys.toList()..sort();
  }

  static String getDefaultCityCode() {
    return cityCodeMap['Ankara']!;
  }
}
