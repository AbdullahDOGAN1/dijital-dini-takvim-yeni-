class DailyContentModel {
  final int gunNo;
  final String tarih;
  final AyetHadis ayetHadis;
  final String tariheBugun;
  final RisaleINur risaleINur;
  final String aksamYemegi;

  DailyContentModel({
    required this.gunNo,
    required this.tarih,
    required this.ayetHadis,
    required this.tariheBugun,
    required this.risaleINur,
    required this.aksamYemegi,
  });

  factory DailyContentModel.fromJson(Map<String, dynamic> json) {
    return DailyContentModel(
      gunNo: json['gun_no'] ?? 0,
      tarih: json['tarih'] ?? '',
      ayetHadis: AyetHadis.fromJson(json['ayet_hadis'] ?? {}),
      tariheBugun: json['tarihte_bugun'] ?? '',
      risaleINur: RisaleINur.fromJson(json['risale_i_nur'] ?? {}),
      aksamYemegi: json['aksam_yemegi'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gun_no': gunNo,
      'tarih': tarih,
      'ayet_hadis': ayetHadis.toJson(),
      'tarihte_bugun': tariheBugun,
      'risale_i_nur': risaleINur.toJson(),
      'aksam_yemegi': aksamYemegi,
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




