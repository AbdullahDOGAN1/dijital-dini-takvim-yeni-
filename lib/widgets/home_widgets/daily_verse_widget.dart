import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/daily_content_model.dart';
import '../../services/daily_content_service.dart';

class DailyVerseWidget extends StatefulWidget {
  const DailyVerseWidget({super.key});

  @override
  State<DailyVerseWidget> createState() => _DailyVerseWidgetState();
}

class _DailyVerseWidgetState extends State<DailyVerseWidget> {
  DailyContentModel? _todayContent;
  bool _isLoading = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadDailyContent();
  }

  Future<void> _loadDailyContent() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final content = await DailyContentService.loadDailyContent();
      final today = DateTime.now();
      final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays + 1;
      final todayIndex = (dayOfYear - 1).clamp(0, content.length - 1);
      
      setState(() {
        _todayContent = content.isNotEmpty ? content[todayIndex] : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading daily content: $e');
    }
  }

  void _shareContent() {
    if (_todayContent != null) {
      final shareText = '''
📖 Bugünün İçeriği

${_todayContent!.ayetHadis.metin.isNotEmpty ? "📿 Ayet/Hadis:\n${_todayContent!.ayetHadis.metin}\n\n" : ""}${_todayContent!.risaleINur.vecize.isNotEmpty ? "✨ Risale-i Nur:\n${_todayContent!.risaleINur.vecize}\n\n" : ""}📅 ${_todayContent!.tarih}

📱 Nur Vakti Uygulaması
      ''';
      
      Share.share(shareText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimationConfiguration.staggeredList(
      position: 4,
      duration: const Duration(milliseconds: 800),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade50,
                  Colors.indigo.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.purple.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _todayContent == null
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Günlük içerik yüklenemedi',
                            style: GoogleFonts.ebGaramond(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.purple.shade600,
                                  Colors.indigo.shade600,
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.auto_stories,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bugünün İçeriği',
                                        style: GoogleFonts.ebGaramond(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        _todayContent!.tarih,
                                        style: GoogleFonts.ebGaramond(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: _shareContent,
                                  icon: const Icon(
                                    Icons.share,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Ayet/Hadis
                                if (_todayContent!.ayetHadis.metin.isNotEmpty)
                                  _buildContentSection(
                                    title: 'Ayet/Hadis',
                                    content: _todayContent!.ayetHadis.metin,
                                    icon: Icons.menu_book,
                                    color: Colors.green.shade600,
                                  ),
                                
                                // Risale-i Nur
                                if (_todayContent!.risaleINur.vecize.isNotEmpty)
                                  _buildContentSection(
                                    title: 'Risale-i Nur',
                                    content: _todayContent!.risaleINur.vecize,
                                    icon: Icons.auto_stories,
                                    color: Colors.blue.shade600,
                                  ),
                                
                                // Tarihe Bugün
                                if (_todayContent!.tariheBugun.isNotEmpty)
                                  _buildContentSection(
                                    title: 'Tarihte Bugün',
                                    content: _todayContent!.tariheBugun,
                                    icon: Icons.history,
                                    color: Colors.orange.shade600,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    if (content.isEmpty) return const SizedBox.shrink();

    // Show only first 100 characters if not expanded
    final displayContent = _isExpanded 
        ? content 
        : content.length > 100 
            ? '${content.substring(0, 100)}...'
            : content;
    
    final needsExpansion = content.length > 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.ebGaramond(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Content text
          Text(
            displayContent,
            style: GoogleFonts.ebGaramond(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
            textAlign: TextAlign.justify,
          ),
          
          // Expand/Collapse button
          if (needsExpansion)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: color,
                ),
                label: Text(
                  _isExpanded ? 'Daha Az' : 'Devamını Oku',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
