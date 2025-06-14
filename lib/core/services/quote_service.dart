import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../models/quote_model.dart';
import 'local_favorites_service.dart';

class QuoteService {
  // Using ZenQuotes API - no CORS restrictions
  static const String baseUrl = 'https://zenquotes.io/api';
  
  // Initialize favorites service
  final LocalFavoritesService _favoritesService = LocalFavoritesService();
  
  // Cache for quotes to improve performance
  static final Map<String, List<QuoteModel>> _quotesCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 10);
  
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

  // Get quotes by category with caching and faster loading
  Future<List<QuoteModel>> getQuotesByCategory(String categoryId) async {
    print('📚 Fetching quotes for category: $categoryId');
    
    // Check cache first
    if (_quotesCache.containsKey(categoryId) && _cacheTimestamps.containsKey(categoryId)) {
      final cacheTime = _cacheTimestamps[categoryId]!;
      if (DateTime.now().difference(cacheTime) < _cacheExpiry) {
        print('💾 Using cached quotes for $categoryId');
        final cachedQuotes = _quotesCache[categoryId]!;
        // Update favorite status for cached quotes
        for (var quote in cachedQuotes) {
          quote.isFavorite = await _favoritesService.isQuoteFavorited(quote.id);
        }
        return cachedQuotes;
      }
    }
    
    // Load local quotes immediately (fast fallback)
    final localQuotes = await _getLocalQuotes(categoryId);
    
    // Try API with very short timeout for better UX
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/quotes'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'QuoteableApp/1.0',
        },
      ).timeout(const Duration(seconds: 2)); // Very short timeout

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Transform the data to match your QuoteModel
        final quotes = data.take(15).map((quoteData) {
          return QuoteModel(
            id: DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString(),
            text: quoteData['q'] ?? quoteData['text'] ?? '',
            author: quoteData['a'] ?? quoteData['author'] ?? 'Unknown',
            isFavorite: false,
          );
        }).where((quote) => quote.text.isNotEmpty).toList();
        
        if (quotes.isNotEmpty) {
          // Cache the quotes
          _quotesCache[categoryId] = quotes;
          _cacheTimestamps[categoryId] = DateTime.now();
          
          // Update favorite status for all quotes
          for (var quote in quotes) {
            quote.isFavorite = await _favoritesService.isQuoteFavorited(quote.id);
          }
          print('✅ API quotes loaded and cached for $categoryId');
          return quotes;
        }
      }
    } catch (e) {
      print('⚠️ API error (using local quotes): $e');
    }
    
    // Use local quotes as fallback
    print('📖 Using local asset quotes for category: $categoryId');
    
    // Cache local quotes too
    _quotesCache[categoryId] = localQuotes;
    _cacheTimestamps[categoryId] = DateTime.now();
    
    // Update favorite status
    for (var quote in localQuotes) {
      quote.isFavorite = await _favoritesService.isQuoteFavorited(quote.id);
    }
    
    return localQuotes;
  }

  // Get random quote with caching
  Future<QuoteModel> getRandomQuote() async {
    try {
      // Try ZenQuotes random quote with short timeout
      final response = await http.get(
        Uri.parse('$baseUrl/random'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'QuoteableApp/1.0',
        },
      ).timeout(const Duration(seconds: 3));

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

  // Search quotes with caching
  Future<List<QuoteModel>> searchQuotes(String query) async {
    print('🔍 Searching local quotes for: $query');
    
    final allQuotes = <QuoteModel>[];
    
    // Search through cached quotes first, then local
    for (String category in categoryToTypeMap.keys) {
      List<QuoteModel> categoryQuotes;
      
      // Use cached quotes if available
      if (_quotesCache.containsKey(category) && _cacheTimestamps.containsKey(category)) {
        final cacheTime = _cacheTimestamps[category]!;
        if (DateTime.now().difference(cacheTime) < _cacheExpiry) {
          categoryQuotes = _quotesCache[category]!;
        } else {
          categoryQuotes = await _getLocalQuotes(category);
        }
      } else {
        categoryQuotes = await _getLocalQuotes(category);
      }
      
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

  // Load quotes from local assets with caching
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

  // Clear cache (useful for refresh)
  static void clearCache() {
    _quotesCache.clear();
    _cacheTimestamps.clear();
    print('🗑️ Quote cache cleared');
  }
}
