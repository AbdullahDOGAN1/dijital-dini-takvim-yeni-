import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'features/calendar_page/widgets/daily_page_widget.dart';
import 'models/daily_content_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dijital Dini Takvim',
      theme: AppTheme.getThemeData(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data
    final sampleData = DailyContentModel(
      frontPage: PageFront(
        historicalEvent: HistoricalEvent(
          year: 1453,
          event: "Fatih Sultan Mehmet, İstanbul'u fethetti.",
        ),
        risaleQuote: RisaleQuote(
          text: "Bismillah her hayrın başıdır. Biz dahi başta ona başlarız.",
          source: "Sözler, Birinci Söz",
        ),
      ),
      backPage: PageBack(
        dailyVerseOrHadith: ContentItem(
          type: "Ayet",
          text: "Yaratan Rabbinin adıyla oku.",
          source: "Alak Suresi, 1. Ayet",
        ),
        dailyMenu: DailyMenu(
          soup: "Domates Çorbası",
          mainCourse: "Karnıyarık",
          dessert: "Güllaç",
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dijital Dini Takvim'),
        centerTitle: true,
      ),
      body: DailyPageWidget(content: sampleData),
    );
  }
}
