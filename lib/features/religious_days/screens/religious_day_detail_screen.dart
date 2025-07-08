import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/religious_day_model.dart';
import '../../../models/favorite_model.dart';
import '../../../services/favorites_service.dart';
import '../../../core/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class ReligiousDayDetailScreen extends StatefulWidget {
  final ReligiousDay religiousDay;

  const ReligiousDayDetailScreen({
    Key? key,
    required this.religiousDay,
  }) : super(key: key);

  @override
  State<ReligiousDayDetailScreen> createState() => _ReligiousDayDetailScreenState();
}

class _ReligiousDayDetailScreenState extends State<ReligiousDayDetailScreen> {
  bool _isFavorite = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  void _checkFavoriteStatus() async {
    try {
      final favorites = await FavoritesService.getFavorites();
      setState(() {
        _isFavorite = favorites.any((fav) => 
          fav.title == widget.religiousDay.name && 
          fav.content == widget.religiousDay.description
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleFavorite() async {
    try {
      if (_isFavorite) {
        final favorites = await FavoritesService.getFavorites();
        final favoriteItem = favorites.firstWhere(
          (fav) => fav.title == widget.religiousDay.name && 
                   fav.content == widget.religiousDay.description,
        );
        await FavoritesService.removeFromFavorites(favoriteItem.id);
      } else {
        final newFavorite = FavoriteModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: '${widget.religiousDay.date.day}/${widget.religiousDay.date.month}/${widget.religiousDay.date.year}',
          title: widget.religiousDay.name,
          content: widget.religiousDay.description,
          type: 'religious_day',
          addedDate: DateTime.now(),
        );
        await FavoritesService.addToFavorites(newFavorite);
      }
      setState(() {
        _isFavorite = !_isFavorite;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite 
              ? 'Favorilere eklendi' 
              : 'Favorilerden kaldırıldı',
            style: GoogleFonts.ebGaramond(),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bir hata oluştu: $e',
            style: GoogleFonts.ebGaramond(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareReligiousDay() {
    String traditions = '';
    if (widget.religiousDay.traditions.isNotEmpty) {
      traditions = '\n📿 Gelenekler:\n${widget.religiousDay.traditions.join('\n• ')}';
    }

    String prayers = '';
    if (widget.religiousDay.prayers.isNotEmpty) {
      prayers = '\n🤲 Dualar:\n${widget.religiousDay.prayers.join('\n• ')}';
    }

    final String shareText = '''
${widget.religiousDay.name}
${widget.religiousDay.date.day}/${widget.religiousDay.date.month}/${widget.religiousDay.date.year}
${widget.religiousDay.hijriDate}

${widget.religiousDay.description}

${widget.religiousDay.importance.isNotEmpty ? '\n🌟 Önemi:\n${widget.religiousDay.importance}' : ''}$traditions$prayers

Nur Vakti uygulamasından paylaşıldı.
''';
    
    Share.share(shareText, subject: widget.religiousDay.name);
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'kandil':
        return '🕌';
      case 'bayram':
        return '🌙';
      case 'ozel_gun':
        return '⭐';
      default:
        return '📅';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = settingsProvider.themeMode == ThemeMode.dark || 
                       (settingsProvider.themeMode == ThemeMode.system && 
                        MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.religiousDay.name,
          style: GoogleFonts.ebGaramond(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: widget.religiousDay.categoryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
              onPressed: _toggleFavorite,
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareReligiousDay,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.religiousDay.categoryColor,
                    widget.religiousDay.categoryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getCategoryIcon(widget.religiousDay.category),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.religiousDay.categoryDisplayName,
                                style: GoogleFonts.ebGaramond(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.religiousDay.name,
                      style: GoogleFonts.ebGaramond(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.white.withOpacity(0.9),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.religiousDay.date.day}/${widget.religiousDay.date.month}/${widget.religiousDay.date.year}',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '• ${widget.religiousDay.hijriDate}',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Açıklama
                  _buildSection(
                    title: 'Açıklama',
                    content: widget.religiousDay.description,
                    icon: Icons.info_outline,
                    isDarkMode: isDarkMode,
                  ),
                  
                  // Önemi
                  if (widget.religiousDay.importance.isNotEmpty)
                    _buildSection(
                      title: 'Önemi',
                      content: widget.religiousDay.importance,
                      icon: Icons.star_outline,
                      isDarkMode: isDarkMode,
                    ),
                  
                  // Gelenekler
                  if (widget.religiousDay.traditions.isNotEmpty)
                    _buildListSection(
                      title: 'Gelenekler',
                      items: widget.religiousDay.traditions,
                      icon: Icons.favorite_outline,
                      isDarkMode: isDarkMode,
                    ),
                  
                  // Dualar
                  if (widget.religiousDay.prayers.isNotEmpty)
                    _buildListSection(
                      title: 'Dualar',
                      items: widget.religiousDay.prayers,
                      icon: Icons.auto_stories,
                      isDarkMode: isDarkMode,
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _toggleFavorite,
                          icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
                          label: Text(
                            _isFavorite ? 'Favorilerden Kaldır' : 'Favorilere Ekle',
                            style: GoogleFonts.ebGaramond(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFavorite ? Colors.pink : Colors.pink.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _shareReligiousDay,
                          icon: const Icon(Icons.share),
                          label: Text(
                            'Paylaş',
                            style: GoogleFonts.ebGaramond(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.religiousDay.categoryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
    required bool isDarkMode,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      child: Card(
        elevation: 2,
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: widget.religiousDay.categoryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.ebGaramond(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: GoogleFonts.ebGaramond(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white.withOpacity(0.9) : Colors.black87,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListSection({
    required String title,
    required List<String> items,
    required IconData icon,
    required bool isDarkMode,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      child: Card(
        elevation: 2,
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: widget.religiousDay.categoryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.ebGaramond(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 16,
                        color: widget.religiousDay.categoryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.ebGaramond(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white.withOpacity(0.9) : Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
