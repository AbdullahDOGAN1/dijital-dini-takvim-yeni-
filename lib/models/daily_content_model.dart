class DailyContentModel {
  final int gunNo;
  final String tarih;
  final String miladiTarih;
  final AyetHadis ayetHadis;
  final String tarihteBugun;
  final RisaleINur risaleINur;
  final String aksamYemegi;
  final Map<String, dynamic>? frontPage;
  final Map<String, dynamic>? backPage;

  DailyContentModel({
    required this.gunNo,
    required this.tarih,
    required this.miladiTarih,
    required this.ayetHadis,
    required this.tarihteBugun,
    required this.risaleINur,
    required this.aksamYemegi,
    this.frontPage,
    this.backPage,
  });

  factory DailyContentModel.fromJson(Map<String, dynamic> json) {
    return DailyContentModel(
      gunNo: json['gun_no'] ?? 0,
      tarih: json['tarih'] ?? '',
      miladiTarih: json['miladi_tarih'] ?? '',
      ayetHadis: AyetHadis.fromJson(json['ayet_hadis'] ?? {}),
      tarihteBugun: json['tarihte_bugun'] ?? '',
      risaleINur: RisaleINur.fromJson(json['risale_i_nur'] ?? {}),
      aksamYemegi: json['aksam_yemegi'] ?? '',
      frontPage: json['front_page'],
      backPage: json['back_page'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gun_no': gunNo,
      'tarih': tarih,
      'miladi_tarih': miladiTarih,
      'ayet_hadis': ayetHadis.toJson(),
      'tarihte_bugun': tarihteBugun,
      'risale_i_nur': risaleINur.toJson(),
      'aksam_yemegi': aksamYemegi,
      'front_page': frontPage,
      'back_page': backPage,
    };
  }
}

class AyetHadis {
  final String metin;
  final String kaynak;

  AyetHadis({
    required this.metin,
    required this.kaynak,
  });

  factory AyetHadis.fromJson(Map<String, dynamic> json) {
    return AyetHadis(
      metin: json['metin'] ?? '',
      kaynak: json['kaynak'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metin': metin,
      'kaynak': kaynak,
    };
  }
}


class RisaleINur {
  final String vecize;
  final String kaynak;

  RisaleINur({
    required this.vecize,
    required this.kaynak,
  });

  factory RisaleINur.fromJson(Map<String, dynamic> json) {
    return RisaleINur(
      vecize: json['vecize'] ?? '',
      kaynak: json['kaynak'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vecize': vecize,
      'kaynak': kaynak,
    };
  }
}




