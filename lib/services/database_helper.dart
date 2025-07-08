import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static DatabaseHelper get instance => _instance;

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Get the directory for storing the database
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'nur_vakti_favorites.db');

    // Open the database
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        favorite_type TEXT NOT NULL,
        content_text TEXT NOT NULL,
        content_source TEXT NOT NULL,
        date_added TEXT NOT NULL,
        page_date TEXT NOT NULL
      )
    ''');
  }

  // Add a new favorite
  Future<int> addFavorite({
    required String favoriteType,
    required String contentText,
    required String contentSource,
    required String pageDate,
  }) async {
    print('DEBUG DatabaseHelper: addFavorite called with:');
    print('  favoriteType: $favoriteType');
    print('  contentText: $contentText');
    print('  contentSource: $contentSource');
    print('  pageDate: $pageDate');
    
    final db = await database;
    print('DEBUG DatabaseHelper: Database connection established');
    
    // Check if this exact content already exists
    final existing = await db.query(
      'favorites',
      where: 'favorite_type = ? AND content_text = ? AND page_date = ?',
      whereArgs: [favoriteType, contentText, pageDate],
    );
    
    print('DEBUG DatabaseHelper: Existing records found: ${existing.length}');
    
    if (existing.isNotEmpty) {
      print('DEBUG DatabaseHelper: Content already exists, throwing exception');
      throw Exception('Bu içerik zaten favorilerde mevcut');
    }
    
    final result = await db.insert('favorites', {
      'favorite_type': favoriteType,
      'content_text': contentText,
      'content_source': contentSource,
      'date_added': DateTime.now().toIso8601String(),
      'page_date': pageDate,
    });
    
    print('DEBUG DatabaseHelper: Insert result: $result');
    return result;
  }

  // Get all favorites
  Future<List<Map<String, dynamic>>> getAllFavorites() async {
    final db = await database;
    return await db.query(
      'favorites',
      orderBy: 'date_added DESC',
    );
  }

  // Get favorites grouped by type for categorized display
  Future<Map<String, List<Map<String, dynamic>>>> getFavorites() async {
    print('DEBUG DatabaseHelper: getFavorites() called');
    final db = await database;
    print('DEBUG DatabaseHelper: Database connection established');
    
    final List<Map<String, dynamic>> favorites = await db.query(
      'favorites',
      orderBy: 'date_added DESC',
    );
    
    print('DEBUG DatabaseHelper: Query returned ${favorites.length} favorites');
    for (var fav in favorites) {
      print('DEBUG DatabaseHelper: Favorite: $fav');
    }
    
    // Group favorites by type
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var favorite in favorites) {
      String type = favorite['favorite_type'] as String;
      print('DEBUG DatabaseHelper: Processing favorite of type: $type');
      if (!grouped.containsKey(type)) {
        grouped[type] = [];
        print('DEBUG DatabaseHelper: Created new group for type: $type');
      }
      grouped[type]!.add(favorite);
    }
    
    print('DEBUG DatabaseHelper: Final grouped result: $grouped');
    return grouped;
  }

  // Check if current page has any favorites
  Future<bool> hasPageFavorites(String pageDate) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'page_date = ?',
      whereArgs: [pageDate],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Delete a favorite by id
  Future<int> deleteFavorite(int id) async {
    final db = await database;
    return await db.delete(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Clear all favorites
  Future<int> clearAllFavorites() async {
    final db = await database;
    return await db.delete('favorites');
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    db.close();
  }

  // Check if an item is already in favorites
  Future<bool> isFavorite(String contentText, String favoriteType) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'content_text = ? AND favorite_type = ?',
      whereArgs: [contentText, favoriteType],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Remove a favorite by content and type
  Future<int> removeFavorite(String contentText, String favoriteType) async {
    final db = await database;
    return await db.delete(
      'favorites',
      where: 'content_text = ? AND favorite_type = ?',
      whereArgs: [contentText, favoriteType],
    );
  }
}
