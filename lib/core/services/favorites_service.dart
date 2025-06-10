import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/quote_model.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Save favorite quote to Firestore
  Future<bool> saveFavoriteQuote(QuoteModel quote) async {
    if (_userId == null) return false;
    
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc(quote.id)
          .set({
        'id': quote.id,
        'text': quote.text,
        'author': quote.author,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('Quote saved to favorites: ${quote.id}');
      return true;
    } catch (e) {
      print('Error saving favorite: $e');
      return false;
    }
  }

  // Remove favorite quote from Firestore
  Future<bool> removeFavoriteQuote(String quoteId) async {
    if (_userId == null) return false;
    
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc(quoteId)
          .delete();
      
      print('Quote removed from favorites: $quoteId');
      return true;
    } catch (e) {
      print('Error removing favorite: $e');
      return false;
    }
  }

  // Get all favorite quotes from Firestore
  Future<List<QuoteModel>> getFavoriteQuotes() async {
    if (_userId == null) return [];
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return QuoteModel(
          id: data['id'] ?? doc.id,
          text: data['text'] ?? '',
          author: data['author'] ?? 'Unknown',
          isFavorite: true,
        );
      }).toList();
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }

  // Check if a quote is favorited
  Future<bool> isQuoteFavorited(String quoteId) async {
    if (_userId == null) return false;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc(quoteId)
          .get();
      
      return doc.exists;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  // Stream of favorite quotes (real-time updates)
  Stream<List<QuoteModel>> getFavoriteQuotesStream() {
    if (_userId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('favorites')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return QuoteModel(
          id: data['id'] ?? doc.id,
          text: data['text'] ?? '',
          author: data['author'] ?? 'Unknown',
          isFavorite: true,
        );
      }).toList();
    });
  }
}
