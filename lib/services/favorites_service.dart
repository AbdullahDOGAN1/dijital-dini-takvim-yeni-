import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_model.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorites_list';

  /// Get all favorites
  static Future<List<FavoriteModel>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
      
      return favoritesJson.map((jsonString) {
        final json = jsonDecode(jsonString);
        return FavoriteModel.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error loading favorites: $e');
      return [];
    }
  }

  /// Add to favorites
  static Future<bool> addToFavorites(FavoriteModel favorite) async {
    try {
      final favorites = await getFavorites();
      
      // Check if already exists
      if (favorites.contains(favorite)) {
        return false; // Already in favorites
      }
      
      favorites.add(favorite);
      return await _saveFavorites(favorites);
    } catch (e) {
      print('Error adding to favorites: $e');
      return false;
    }
  }

  /// Remove from favorites
  static Future<bool> removeFromFavorites(String favoriteId) async {
    try {
      final favorites = await getFavorites();
      favorites.removeWhere((fav) => fav.id == favoriteId);
      return await _saveFavorites(favorites);
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }

  /// Check if item is in favorites
  static Future<bool> isFavorite(String favoriteId) async {
    try {
      final favorites = await getFavorites();
      return favorites.any((fav) => fav.id == favoriteId);
    } catch (e) {
      print('Error checking favorites: $e');
      return false;
    }
  }

  /// Save favorites to SharedPreferences
  static Future<bool> _saveFavorites(List<FavoriteModel> favorites) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = favorites.map((fav) {
        return jsonEncode(fav.toJson());
      }).toList();
      
      return await prefs.setStringList(_favoritesKey, favoritesJson);
    } catch (e) {
      print('Error saving favorites: $e');
      return false;
    }
  }

  /// Clear all favorites
  static Future<bool> clearFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_favoritesKey);
    } catch (e) {
      print('Error clearing favorites: $e');
      return false;
    }
  }
}
