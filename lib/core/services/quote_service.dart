import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import '../../models/quote_model.dart';

class QuoteService {
  static const String baseUrl = 'https://api.quotable.io';
  
  // Initialize Cloud Functions with us-central1 region
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  
  // Map our app categories to Quotable API tags
  static Map<String, String> categoryToTagMap = {
    'alone': 'solitude',
    'angry': 'anger',
    'attitude': 'attitude',
    'breakup': 'love',
    'emotional': 'emotions',
    'family': 'family',
    'friends': 'friendship',
    'funny': 'humor',
    'love': 'love',
    'motivational': 'motivational',
    'success': 'success',
    'wisdom': 'wisdom',
  };

  // Fallback quotes for when both API and Cloud Functions fail
  static final Map<String, List<QuoteModel>> _fallbackQuotes = {
    'alone': [
      QuoteModel(id: 'a1', text: 'Sometimes you need to be alone to reflect on life.', author: 'Anonymous'),
      QuoteModel(id: 'a2', text: 'It is better to be alone than in bad company.', author: 'George Washington'),
    ],
    'angry': [
      QuoteModel(id: 'an1', text: 'For every minute you remain angry, you give up sixty seconds of peace of mind.', author: 'Ralph Waldo Emerson'),
      QuoteModel(id: 'an2', text: 'Anger is an acid that can do more harm to the vessel in which it is stored than to anything on which it is poured.', author: 'Mark Twain'),
    ],
    'attitude': [
      QuoteModel(id: 'at1', text: 'Attitude is a little thing that makes a big difference.', author: 'Winston Churchill'),
      QuoteModel(id: 'at2', text: 'Your attitude, not your aptitude, will determine your altitude.', author: 'Zig Ziglar'),
    ],
    'breakup': [
      QuoteModel(id: 'b1', text: 'Sometimes good things fall apart so better things can fall together.', author: 'Marilyn Monroe'),
      QuoteModel(id: 'b2', text: 'The heart will break, but broken live on.', author: 'Lord Byron'),
    ],
    'emotional': [
      QuoteModel(id: 'e1', text: 'The best and most beautiful things in the world cannot be seen or even touched - they must be felt with the heart.', author: 'Helen Keller'),
      QuoteModel(id: 'e2', text: 'Emotions are the colors of the soul.', author: 'Anonymous'),
    ],
    'family': [
      QuoteModel(id: 'f1', text: 'Family is not an important thing. It\'s everything.', author: 'Michael J. Fox'),
      QuoteModel(id: 'f2', text: 'The love of family is life\'s greatest blessing.', author: 'Anonymous'),
    ],
    'friends': [
      QuoteModel(id: 'fr1', text: 'A real friend is one who walks in when the rest of the world walks out.', author: 'Walter Winchell'),
      QuoteModel(id: 'fr2', text: 'Friendship is born at that moment when one person says to another, "What! You too? I thought I was the only one."', author: 'C.S. Lewis'),
    ],
    'funny': [
      QuoteModel(id: 'fu1', text: 'I\'m on a seafood diet. I see food and I eat it.', author: 'Anonymous'),
      QuoteModel(id: 'fu2', text: 'I\'m writing a book. I\'ve got the page numbers done.', author: 'Steven Wright'),
    ],
    'love': [
      QuoteModel(id: 'l1', text: 'Love is composed of a single soul inhabiting two bodies.', author: 'Aristotle'),
      QuoteModel(id: 'l2', text: 'Where there is love there is life.', author: 'Mahatma Gandhi'),
    ],
    'motivational': [
      QuoteModel(id: 'm1', text: 'The only way to do great work is to love what you do.', author: 'Steve Jobs'),
      QuoteModel(id: 'm2', text: 'Don\'t watch the clock; do what it does. Keep going.', author: 'Sam Levenson'),
    ],
    'success': [
      QuoteModel(id: 's1', text: 'Success is not final, failure is not fatal: It is the courage to continue that counts.', author: 'Winston Churchill'),
      QuoteModel(id: 's2', text: 'The secret of success is to do the common thing uncommonly well.', author: 'John D. Rockefeller Jr.'),
    ],
    'wisdom': [
      QuoteModel(id: 'w1', text: 'The only true wisdom is in knowing you know nothing.', author: 'Socrates'),
      QuoteModel(id: 'w2', text: 'Wisdom is not a product of schooling but of the lifelong attempt to acquire it.', author: 'Albert Einstein'),
    ],
  };

  static final QuoteModel _fallbackRandomQuote = QuoteModel(
    id: 'random1',
    text: 'The best way to predict the future is to create it.',
    author: 'Abraham Lincoln',
  );

  // Get quotes by category using Cloud Functions
  Future<List<QuoteModel>> getQuotesByCategory(String categoryId) async {
    try {
      print('Fetching quotes from Cloud Functions for category: $categoryId');
      
      final callable = _functions.httpsCallable('getQuotesByCategory');
      final result = await callable.call({'categoryId': categoryId});
      
      if (result.data['success'] == true) {
        final quotesData = result.data['quotes'] as List;
        print('Successfully fetched ${quotesData.length} quotes from Cloud Functions');
        
        return quotesData.map((quoteData) {
          return QuoteModel(
            id: quoteData['id'],
            text: quoteData['text'],
            author: quoteData['author'],
            isFavorite: false,
          );
        }).toList();
      }
    } catch (e) {
      print('Cloud Functions error: $e');
      
      // If Cloud Functions fail and not on web, try direct API call
      if (!kIsWeb) {
        try {
          print('Trying direct API call...');
          return await _getQuotesDirectly(categoryId);
        } catch (apiError) {
          print('Direct API error: $apiError');
        }
      }
    }
    
    // Use fallback quotes
    print('Using fallback quotes for category: $categoryId');
    final tag = categoryToTagMap[categoryId.toLowerCase()] ?? categoryId.toLowerCase();
    return _fallbackQuotes[tag] ?? _fallbackQuotes['motivational']!;
  }

  // Direct API call for non-web platforms
  Future<List<QuoteModel>> _getQuotesDirectly(String categoryId) async {
    final tag = categoryToTagMap[categoryId.toLowerCase()] ?? categoryId.toLowerCase();
    
    final response = await http.get(
      Uri.parse('$baseUrl/quotes?tags=$tag&limit=10'),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      
      return results.map((quoteData) {
        return QuoteModel(
          id: quoteData['_id'],
          text: quoteData['content'],
          author: quoteData['author'],
          isFavorite: false,
        );
      }).toList();
    } else {
      throw Exception('Failed to load quotes: ${response.statusCode}');
    }
  }

  // Get random quote using Cloud Functions
  Future<QuoteModel> getRandomQuote() async {
    try {
      print('Fetching random quote from Cloud Functions');
      
      final callable = _functions.httpsCallable('getRandomQuote');
      final result = await callable.call();
      
      if (result.data['success'] == true) {
        final quoteData = result.data['quote'];
        print('Successfully fetched random quote from Cloud Functions');
        
        return QuoteModel(
          id: quoteData['id'],
          text: quoteData['text'],
          author: quoteData['author'],
          isFavorite: false,
        );
      }
    } catch (e) {
      print('Cloud Functions error for random quote: $e');
      
      // If Cloud Functions fail and not on web, try direct API call
      if (!kIsWeb) {
        try {
          print('Trying direct API call for random quote...');
          final response = await http.get(
            Uri.parse('$baseUrl/random'),
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            return QuoteModel(
              id: data['_id'],
              text: data['content'],
              author: data['author'],
              isFavorite: false,
            );
          }
        } catch (apiError) {
          print('Direct API error for random quote: $apiError');
        }
      }
    }
    
    // Use fallback quote
    print('Using fallback random quote');
    return _fallbackRandomQuote;
  }

  // Search quotes using Cloud Functions
  Future<List<QuoteModel>> searchQuotes(String query) async {
    try {
      print('Searching quotes via Cloud Functions: $query');
      
      final callable = _functions.httpsCallable('searchQuotes');
      final result = await callable.call({'query': query});
      
      if (result.data['success'] == true) {
        final quotesData = result.data['quotes'] as List;
        print('Successfully found ${quotesData.length} quotes via Cloud Functions');
        
        return quotesData.map((quoteData) {
          return QuoteModel(
            id: quoteData['id'],
            text: quoteData['text'],
            author: quoteData['author'],
            isFavorite: false,
          );
        }).toList();
      }
    } catch (e) {
      print('Cloud Functions error for search: $e');
    }
    
    // Search through fallback quotes
    print('Searching fallback quotes for: $query');
    final allQuotes = _fallbackQuotes.values.expand((quotes) => quotes).toList();
    final lowercaseQuery = query.toLowerCase();
    
    return allQuotes.where((quote) => 
      quote.text.toLowerCase().contains(lowercaseQuery) || 
      quote.author.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  // Save favorite quote using Cloud Functions
  Future<bool> saveFavoriteQuote(QuoteModel quote) async {
    try {
      print('Saving favorite quote via Cloud Functions: ${quote.id}');
      
      final callable = _functions.httpsCallable('saveFavoriteQuote');
      final result = await callable.call({'quote': {
        'id': quote.id,
        'text': quote.text,
        'author': quote.author,
        'isFavorite': true,
      }});
      
      bool success = result.data['success'] == true;
      print('Save favorite result: $success');
      return success;
    } catch (e) {
      print('Error saving favorite: $e');
      return false;
    }
  }

  // Remove favorite quote using Cloud Functions
  Future<bool> removeFavoriteQuote(String quoteId) async {
    try {
      print('Removing favorite quote via Cloud Functions: $quoteId');
      
      final callable = _functions.httpsCallable('removeFavoriteQuote');
      final result = await callable.call({'quoteId': quoteId});
      
      bool success = result.data['success'] == true;
      print('Remove favorite result: $success');
      return success;
    } catch (e) {
      print('Error removing favorite: $e');
      return false;
    }
  }

  // Get favorite quotes using Cloud Functions
  Future<List<QuoteModel>> getFavoriteQuotes() async {
    try {
      print('Fetching favorite quotes via Cloud Functions');
      
      final callable = _functions.httpsCallable('getFavoriteQuotes');
      final result = await callable.call();
      
      if (result.data['success'] == true) {
        final favoritesData = result.data['favorites'] as List;
        print('Successfully fetched ${favoritesData.length} favorite quotes');
        
        return favoritesData.map((quoteData) {
          return QuoteModel(
            id: quoteData['id'],
            text: quoteData['text'],
            author: quoteData['author'],
            isFavorite: true,
          );
        }).toList();
      }
    } catch (e) {
      print('Error getting favorites: $e');
    }
    
    return [];
  }
}
