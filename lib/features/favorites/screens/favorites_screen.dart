import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/database_helper.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  Map<String, List<Map<String, dynamic>>> _groupedFavorites = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      print('DEBUG FavoritesScreen: Loading favorites...');

      // First check raw database data
      final allFavorites = await DatabaseHelper.instance.getAllFavorites();
      print(
        'DEBUG FavoritesScreen: Raw favorites count: ${allFavorites.length}',
      );
      for (var fav in allFavorites) {
        print('DEBUG FavoritesScreen: Raw favorite: $fav');
      }

      // Then get grouped favorites
      final favorites = await DatabaseHelper.instance.getFavorites();
      print('DEBUG FavoritesScreen: Grouped favorites: $favorites');
      print(
        'DEBUG FavoritesScreen: Grouped favorites keys: ${favorites.keys.toList()}',
      );

      setState(() {
        _groupedFavorites = favorites;
        _isLoading = false;
      });

      print(
        'DEBUG FavoritesScreen: State updated, _groupedFavorites: $_groupedFavorites',
      );
    } catch (e) {
      print('Error loading favorites: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromFavorites(int favoriteId) async {
    try {
      await DatabaseHelper.instance.deleteFavorite(favoriteId);

      // Reload favorites to refresh the grouped structure
      await _loadFavorites();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Favorilerden kaldırıldı'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error removing favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Favori kaldırılırken hata oluştu'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearAllFavorites() async {
    try {
      await DatabaseHelper.instance.clearAllFavorites();

      setState(() {
        _groupedFavorites.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tüm favoriler temizlendi'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error clearing favorites: $e');
    }
  }

  // DEBUG: Test için veri ekleme metodu
  Future<void> _addTestFavorite() async {
    try {
      await DatabaseHelper.instance.addFavorite(
        favoriteType: 'Risale-i Nur',
        contentText: 'Test favori içeriği - Risale-i Nur örneği',
        contentSource: 'Test Kaynağı',
        pageDate: '1 Temmuz 2025',
      );
      print('DEBUG: Test favorisi eklendi');
      await _loadFavorites();
    } catch (e) {
      print('DEBUG: Test favorisi eklenirken hata: $e');
    }
  }

  int get _totalFavoritesCount {
    return _groupedFavorites.values.fold(0, (sum, list) => sum + list.length);
  }

  Widget _buildExpansionTile(
    String type,
    List<Map<String, dynamic>> favorites,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        elevation: 2,
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getTypeColor(type),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getTypeIcon(type), color: Colors.white, size: 20),
          ),
          title: Text(
            _getTypeDisplayName(type),
            style: GoogleFonts.ebGaramond(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.brown[800],
            ),
          ),
          subtitle: Text(
            '${favorites.length} öğe',
            style: GoogleFonts.ebGaramond(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          children: favorites
              .map((favorite) => _buildFavoriteCard(favorite))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> favorite) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      favorite['page_date'] ?? '',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red[400], size: 20),
                    onPressed: () => _removeFromFavorites(favorite['id']),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                favorite['content_text'] ?? '',
                style: GoogleFonts.ebGaramond(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              if (favorite['content_source'] != null &&
                  favorite['content_source'].isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '— ${favorite['content_source']}',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Eklenme: ${_formatDate(favorite['date_added'])}',
                style: GoogleFonts.ebGaramond(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Risale-i Nur':
        return Icons.menu_book;
      case 'Ayet/Hadis':
        return Icons.auto_stories;
      case 'Tarihte Bugün':
        return Icons.history_edu;
      default:
        return Icons.bookmark;
    }
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'Risale-i Nur':
        return 'Risale-i Nur';
      case 'Ayet/Hadis':
        return 'Ayet ve Hadisler';
      case 'Tarihte Bugün':
        return 'Tarihte Bugün';
      default:
        return 'Diğer';
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Risale-i Nur':
        return Colors.green;
      case 'Ayet/Hadis':
        return Colors.blue;
      case 'Tarihte Bugün':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}.${date.month}.${date.year}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG FavoritesScreen: build() called');
    print('DEBUG FavoritesScreen: _isLoading = $_isLoading');
    print('DEBUG FavoritesScreen: _groupedFavorites = $_groupedFavorites');
    print(
      'DEBUG FavoritesScreen: _groupedFavorites.isEmpty = ${_groupedFavorites.isEmpty}',
    );
    print(
      'DEBUG FavoritesScreen: _totalFavoritesCount = $_totalFavoritesCount',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Favoriler',
          style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          // DEBUG: Test veri ekleme butonu
          IconButton(
            icon: Icon(Icons.add_circle, color: Colors.yellow),
            onPressed: _addTestFavorite,
            tooltip: 'Test Veri Ekle',
          ),
          if (_totalFavoritesCount > 0)
            IconButton(
              icon: Icon(Icons.clear_all),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Tüm Favorileri Temizle'),
                    content: Text(
                      'Tüm favorilerinizi silmek istediğinizden emin misiniz?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearAllFavorites();
                        },
                        child: Text(
                          'Temizle',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.withOpacity(0.1),
              Colors.purple.withOpacity(0.05),
            ],
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _groupedFavorites.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: Colors.purple.withOpacity(0.5),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Henüz favori eklenmemiş',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 18,
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Takvim sayfalarındaki kalp simgesine uzun basarak\nbeğendiğiniz içerikleri favorilere ekleyebilirsiniz.',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 14,
                        color: Colors.purple.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _groupedFavorites.entries
                    .map((entry) => _buildExpansionTile(entry.key, entry.value))
                    .toList(),
              ),
      ),
    );
  }
}
