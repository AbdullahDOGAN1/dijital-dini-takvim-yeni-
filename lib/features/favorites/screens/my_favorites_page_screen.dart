import 'package:flutter/material.dart';
import '../../../services/database_helper.dart';
import 'package:share_plus/share_plus.dart';

class MyFavoritesPageScreen extends StatefulWidget {
  const MyFavoritesPageScreen({super.key});

  @override
  State<MyFavoritesPageScreen> createState() => _MyFavoritesPageScreenState();
}

class _MyFavoritesPageScreenState extends State<MyFavoritesPageScreen> {
  Map<String, List<Map<String, dynamic>>> _groupedFavorites = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await DatabaseHelper.instance.getFavorites();
      setState(() {
        _groupedFavorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading favorites: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _shareFavorite(Map<String, dynamic> favorite) {
    final shareText = '''
📖 ${favorite['favorite_type'] ?? 'İçerik'}
${favorite['page_date'] ?? ''}

${favorite['content_text'] ?? ''}

Kaynak: ${favorite['content_source'] ?? ''}

🌙 Nur Vakti Uygulaması
''';

    Share.share(
      shareText,
      subject: '${favorite['favorite_type']} - ${favorite['page_date']}',
    );
  }

  Future<void> _deleteFavorite(int favoriteId) async {
    try {
      await DatabaseHelper.instance.deleteFavorite(favoriteId);
      _loadFavorites(); // Listeyi yenile
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Favori silindi'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme hatası: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoriler'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.withOpacity(0.1), Colors.purple.withOpacity(0.05)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _groupedFavorites.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 80,
                          color: Colors.purple,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Henüz favori eklenmemiş',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _groupedFavorites.entries
                        .map((entry) => Card(
                              margin: const EdgeInsets.all(8),
                              child: ExpansionTile(
                                title: Text(entry.key),
                                children: entry.value.map((fav) => ListTile(
                                  title: Text(fav['content_text'] ?? ''),
                                  subtitle: Text(fav['page_date'] ?? ''),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.share, size: 20),
                                        onPressed: () => _shareFavorite(fav),
                                        tooltip: 'Paylaş',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                        onPressed: () => _deleteFavorite(fav['id']),
                                        tooltip: 'Sil',
                                      ),
                                    ],
                                  ),
                                )).toList(),
                              ),
                            ))
                        .toList(),
                  ),
      ),
    );
  }
}
