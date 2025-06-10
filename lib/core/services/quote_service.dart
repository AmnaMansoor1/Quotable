import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../.././models/quote_model.dart';
import 'favorites_service.dart'; // Use this for Firestore
// import 'local_favorites_service.dart'; // Use this for SharedPreferences

class QuoteService {
  // Using ZenQuotes API - no CORS restrictions
  static const String baseUrl = 'https://zenquotes.io/api';
  
  // Initialize favorites service
  final FavoritesService _favoritesService = FavoritesService();
  // final LocalFavoritesService _favoritesService = LocalFavoritesService(); // For local storage
  
  // Map our app categories to available quote types
  static Map<String, String> categoryToTypeMap = {
    'alone': 'inspirational',
    'angry': 'motivational',
    'attitude': 'success',
    'breakup': 'love',
    'emotional': 'inspirational',
    'family': 'happiness',
    'friends': 'friendship',
    'funny': 'funny',
    'love': 'love',
    'motivational': 'motivational',
    'success': 'success',
    'wisdom': 'wisdom',
  };

  // Get quotes by category with favorite status
  Future<List<QuoteModel>> getQuotesByCategory(String categoryId) async {
    try {
      print('Fetching quotes for category: $categoryId');
      
      // Try ZenQuotes API first
      final response = await http.get(
        Uri.parse('$baseUrl/quotes'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'QuoteableApp/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      List<QuoteModel> quotes = [];

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Filter and transform quotes
        quotes = data.take(10).map((quoteData) {
          return QuoteModel(
            id: DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString(),
            text: quoteData['q'] ?? quoteData['text'] ?? '',
            author: quoteData['a'] ?? quoteData['author'] ?? 'Unknown',
            isFavorite: false,
          );
        }).where((quote) => quote.text.isNotEmpty).toList();
      }

      // Fallback to local assets if API fails
      if (quotes.isEmpty) {
        print('Using local asset quotes for category: $categoryId');
        quotes = await _getLocalQuotes(categoryId);
      }

      // Update favorite status for all quotes
      for (var quote in quotes) {
        quote.isFavorite = await _favoritesService.isQuoteFavorited(quote.id);
      }

      return quotes;
    } catch (e) {
      print('API error: $e');
      // Fallback to local assets
      final quotes = await _getLocalQuotes(categoryId);
      
      // Update favorite status
      for (var quote in quotes) {
        quote.isFavorite = await _favoritesService.isQuoteFavorited(quote.id);
      }
      
      return quotes;
    }
  }

  // Get random quote with favorite status
  Future<QuoteModel> getRandomQuote() async {
    try {
      // Try ZenQuotes random quote
      final response = await http.get(
        Uri.parse('$baseUrl/random'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'QuoteableApp/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final quoteData = data.first;
          final quote = QuoteModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: quoteData['q'] ?? quoteData['text'] ?? '',
            author: quoteData['a'] ?? quoteData['author'] ?? 'Unknown',
            isFavorite: false,
          );
          
          // Check favorite status
          quote.isFavorite = await _favoritesService.isQuoteFavorited(quote.id);
          return quote;
        }
      }
    } catch (e) {
      print('Random quote API error: $e');
    }
    
    // Fallback to local random quote
    final allCategories = categoryToTypeMap.keys.toList();
    final randomCategory = allCategories[Random().nextInt(allCategories.length)];
    final quotes = await _getLocalQuotes(randomCategory);
    final quote = quotes.isNotEmpty ? quotes[Random().nextInt(quotes.length)] : _getDefaultQuote();
    
    // Check favorite status
    quote.isFavorite = await _favoritesService.isQuoteFavorited(quote.id);
    return quote;
  }

  // Search quotes with favorite status
  Future<List<QuoteModel>> searchQuotes(String query) async {
    print('Searching local quotes for: $query');
    
    final allQuotes = <QuoteModel>[];
    
    // Search through all local categories
    for (String category in categoryToTypeMap.keys) {
      final categoryQuotes = await _getLocalQuotes(category);
      allQuotes.addAll(categoryQuotes);
    }
    
    final lowercaseQuery = query.toLowerCase();
    final searchResults = allQuotes.where((quote) => 
      quote.text.toLowerCase().contains(lowercaseQuery) || 
      quote.author.toLowerCase().contains(lowercaseQuery)
    ).toList();

    // Update favorite status for search results
    for (var quote in searchResults) {
      quote.isFavorite = await _favoritesService.isQuoteFavorited(quote.id);
    }

    return searchResults;
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(QuoteModel quote) async {
    if (quote.isFavorite) {
      final success = await _favoritesService.removeFavoriteQuote(quote.id);
      if (success) {
        quote.isFavorite = false;
      }
      return success;
    } else {
      final success = await _favoritesService.saveFavoriteQuote(quote);
      if (success) {
        quote.isFavorite = true;
      }
      return success;
    }
  }

  // Get favorite quotes
  Future<List<QuoteModel>> getFavoriteQuotes() async {
    return await _favoritesService.getFavoriteQuotes();
  }

  // Load quotes from local assets
  Future<List<QuoteModel>> _getLocalQuotes(String categoryId) async {
    try {
      final String jsonString = await rootBundle.loadString('assets/quotes/${categoryId}.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      return jsonData.map((quoteData) {
        return QuoteModel(
          id: quoteData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          text: quoteData['text'] ?? '',
          author: quoteData['author'] ?? 'Unknown',
          isFavorite: false,
        );
      }).toList();
    } catch (e) {
      print('Error loading local quotes for $categoryId: $e');
      return [_getDefaultQuote()];
    }
  }

  // Default quote when everything fails
  QuoteModel _getDefaultQuote() {
    return QuoteModel(
      id: 'default_1',
      text: 'The best way to predict the future is to create it.',
      author: 'Abraham Lincoln',
      isFavorite: false,
    );
  }
}
