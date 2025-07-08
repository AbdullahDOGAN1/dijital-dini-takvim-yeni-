import 'package:flutter/material.dart';
import '../../../models/daily_content_model.dart';
import '../../../services/daily_content_service.dart';
import '../../../services/database_helper.dart';
import 'package:share_plus/share_plus.dart';

class DailyContentScreen extends StatefulWidget {
  final int? dayNumber;
  
  const DailyContentScreen({super.key, this.dayNumber});

  @override
  State<DailyContentScreen> createState() => _DailyContentScreenState();
}

class _DailyContentScreenState extends State<DailyContentScreen> {
  DailyContentModel? _content;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      DailyContentModel? content;
      if (widget.dayNumber != null) {
        content = await DailyContentService.getContentForDay(widget.dayNumber!);
      } else {
        content = await DailyContentService.getTodaysContent();
      }

      setState(() {
        _content = content;
        _isLoading = false;
        if (content == null) {
          _error = 'Bu gün için içerik bulunamadı';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'İçerik yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildFavoriteButton(String category, String content, String source) {
    return FutureBuilder<bool>(
      future: DatabaseHelper.instance.isFavorite(content, category),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;
        return IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.grey,
            size: 20,
          ),
          onPressed: () => _toggleFavorite(category, content, source),
        );
      },
    );
  }

  Future<void> _toggleFavorite(String category, String content, String source) async {
    try {
      final isFavorite = await DatabaseHelper.instance.isFavorite(content, category);
      
      if (isFavorite) {
        await DatabaseHelper.instance.removeFavorite(content, category);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$category favorilerden çıkarıldı'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        await DatabaseHelper.instance.addFavorite(
          favoriteType: category,
          contentText: content,
          contentSource: source,
          pageDate: _content?.tarih ?? '',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$category favorilere eklendi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
      // State'i yenile
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareDetailContent(String category, String content, String source) {
    final shareText = '''
📖 $category
${_content?.tarih ?? ''}

$content

📚 Kaynak: $source

🌙 Nur Vakti Uygulaması
''';
    
    Share.share(
      shareText,
      subject: '$category - ${_content?.tarih ?? ''}',
    );
  }

  void _shareSimpleContent(String category, String content) {
    final shareText = '''
📖 $category
${_content?.tarih ?? ''}

$content

🌙 Nur Vakti Uygulaması
''';
    
    Share.share(
      shareText,
      subject: '$category - ${_content?.tarih ?? ''}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dayNumber != null 
            ? '${widget.dayNumber}. Gün' 
            : 'Bugünün İçeriği'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadContent,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : _content == null
                  ? const Center(child: Text('İçerik bulunamadı'))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_content == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarih Başlığı
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    _content!.tarih,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          // Ayet/Hadis
          _buildContentCard(
            title: 'Ayet/Hadis',
            icon: Icons.menu_book,
            content: _content!.ayetHadis.metin,
            source: _content!.ayetHadis.kaynak,
            color: Colors.green,
          ),

          const SizedBox(height: 16),

          // Risale-i Nur
          _buildContentCard(
            title: 'Risale-i Nur',
            icon: Icons.auto_stories,
            content: _content!.risaleINur.vecize,
            source: _content!.risaleINur.kaynak,
            color: Colors.blue,
          ),

          const SizedBox(height: 16),

          // Tarihte Bugün
          _buildSimpleContentCard(
            title: 'Tarihte Bugün',
            icon: Icons.history,
            content: _content!.tarihteBugun,
            color: Colors.orange,
          ),

          const SizedBox(height: 16),

          // Akşam Yemeği
          _buildSimpleContentCard(
            title: 'Akşam Yemeği Önerisi',
            icon: Icons.restaurant,
            content: _content!.aksamYemegi,
            color: Colors.red,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildContentCard({
    required String title,
    required IconData icon,
    required String content,
    required String source,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                // Paylaş butonu
                IconButton(
                  onPressed: () => _shareDetailContent(title, content, source),
                  icon: const Icon(Icons.share, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  tooltip: 'Paylaş',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(
                content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.source, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    source,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                // Favori butonu
                _buildFavoriteButton(title, content, source),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleContentCard({
    required String title,
    required IconData icon,
    required String content,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                // Paylaş butonu
                IconButton(
                  onPressed: () => _shareSimpleContent(title, content),
                  icon: const Icon(Icons.share, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  tooltip: 'Paylaş',
                ),
                _buildFavoriteButton(title, content, ''),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(
                content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
