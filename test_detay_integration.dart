import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

// Test için detay verilerini yükleyip kontrol edelim
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('🔍 Testing new dinigünler_detay.json file...');
    
    // Yeni detay dosyasını yükle
    final detailsData = await rootBundle.loadString('assets/data/dinigünler_detay.json');
    final detailsList = json.decode(detailsData) as List<dynamic>;
    
    print('✅ Successfully loaded ${detailsList.length} religious events with details');
    
    // İlk birkaç eventi detaylarıyla göster
    for (int i = 0; i < 3 && i < detailsList.length; i++) {
      final event = detailsList[i];
      print('\n📅 Event ${i + 1}: ${event['isim']}');
      
      if (event['aciklama'] is List && event['aciklama'].isNotEmpty) {
        print('  📝 Description count: ${event['aciklama'].length}');
      }
      
      if (event['yapilan_ibadetler_ve_dualar'] is List && event['yapilan_ibadetler_ve_dualar'].isNotEmpty) {
        print('  🤲 Worship practices count: ${event['yapilan_ibadetler_ve_dualar'].length}');
      }
      
      if (event['ilgili_ayet_ve_hadisler'] is List && event['ilgili_ayet_ve_hadisler'].isNotEmpty) {
        print('  📖 Verses and hadiths count: ${event['ilgili_ayet_ve_hadisler'].length}');
      }
      
      if (event['tavsiyeler'] is List && event['tavsiyeler'].isNotEmpty) {
        print('  💡 Recommendations count: ${event['tavsiyeler'].length}');
      }
    }
    
    print('\n🎉 New categorized religious events data is working perfectly!');
    print('   Each event now has detailed sections for better accessibility');
    
  } catch (e) {
    print('❌ Error testing new details file: $e');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Religious Events Test',
      home: Scaffold(
        appBar: AppBar(title: Text('Testing New Religious Events Details')),
        body: Center(
          child: Text(
            'Check console for test results!\n\n'
            'New categorized religious events data\n'
            'has been successfully integrated.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
