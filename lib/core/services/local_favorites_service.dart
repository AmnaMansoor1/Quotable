import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/quote_model.dart';

class LocalFavoritesService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user ID for local storage key
  String get _favoritesKey => 'favorites_${_auth.currentUser?.uid ?? 'anonymous'}';

  // Save favorite quote locally
  Future<bool> saveFavoriteQuote(QuoteModel quote) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await getFavoriteQuotes();
      
      // Check if quote is already in favorites
      if (!favorites.any((fav) => fav.id == quote.id)) {
        favorites.add(quote);
        
        // Convert to JSON and save
        final favoritesJson = favorites.map((q) => {
          'id': q.id,
          'text': q.text,
          'author': q.author,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        }).toList();
        
        await prefs.setString(_favoritesKey, json.encode(favoritesJson));
        print('Quote saved to local favorites: ${quote.id}');
        return true;
      }
      return false;
    } catch (e) {
      print('Error saving favorite locally: $e');
      return false;
    }
  }

  // Remove favorite quote locally
  Future<bool> removeFavoriteQuote(String quoteId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await getFavoriteQuotes();
      
      favorites.removeWhere((quote) => quote.id == quoteId);
      
      // Convert to JSON and save
      final favoritesJson = favorites.map((q) => {
        'id': q.id,
        'text': q.text,
        'author': q.author,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      }).toList();
      
      await prefs.setString(_favoritesKey, json.encode(favoritesJson));
      print('Quote removed from local favorites: $quoteId');
      return true;
    } catch (e) {
      print('Error removing favorite locally: $e');
      return false;
    }
  }

  // Get all favorite quotes locally
  Future<List<QuoteModel>> getFavoriteQuotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesString = prefs.getString(_favoritesKey);
      
      if (favoritesString == null) return [];
      
      final List<dynamic> favoritesJson = json.decode(favoritesString);
      
      return favoritesJson.map((item) {
        return QuoteModel(
          id: item['id'] ?? '',
          text: item['text'] ?? '',
          author: item['author'] ?? 'Unknown',
          isFavorite: true,
        );
      }).toList();
    } catch (e) {
      print('Error getting local favorites: $e');
      return [];
    }
  }

  // Check if a quote is favorited locally
  Future<bool> isQuoteFavorited(String quoteId) async {
    try {
      final favorites = await getFavoriteQuotes();
      return favorites.any((quote) => quote.id == quoteId);
    } catch (e) {
      print('Error checking local favorite status: $e');
      return false;
    }
  }

  // Clear all favorites (useful for logout)
  Future<void> clearFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoritesKey);
      print('Local favorites cleared');
    } catch (e) {
      print('Error clearing local favorites: $e');
    }
  }
}
