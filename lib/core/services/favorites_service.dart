import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/quote_model.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Save favorite quote to Firestore with enhanced debugging
  Future<bool> saveFavoriteQuote(QuoteModel quote) async {
    print('🔥 FIRESTORE DEBUG: Starting saveFavoriteQuote');
    
    if (_userId == null) {
      print('❌ ERROR: User not authenticated');
      print('   Current user: ${_auth.currentUser}');
      return false;
    }
    
    print('✅ User authenticated: $_userId');
    print('📝 Quote to save:');
    print('   ID: ${quote.id}');
    print('   Text: ${quote.text.substring(0, 50)}...');
    print('   Author: ${quote.author}');
    
    try {
      // Test Firestore connection first
      print('🧪 Testing Firestore connection...');
      await _firestore.enableNetwork();
      print('✅ Firestore network enabled');
      
      // Create the document reference
      final docRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc(quote.id);
      
      print('📍 Document path: users/$_userId/favorites/${quote.id}');
      
      // Prepare the data
      final data = {
        'id': quote.id,
        'text': quote.text,
        'author': quote.author,
        'createdAt': FieldValue.serverTimestamp(),
        'addedBy': _userId,
        'platform': 'flutter',
      };
      
      print('📦 Data to save: $data');
      
      // Save to Firestore with timeout
      print('💾 Saving to Firestore...');
      await docRef.set(data).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Firestore write timeout after 10 seconds');
        },
      );
      
      print('✅ SUCCESS: Quote saved to Firestore!');
      
      // Verify the save by reading it back
      print('🔍 Verifying save by reading back...');
      final savedDoc = await docRef.get();
      if (savedDoc.exists) {
        print('✅ VERIFIED: Document exists in Firestore');
        print('📄 Saved data: ${savedDoc.data()}');
      } else {
        print('❌ WARNING: Document not found after save');
      }
      
      return true;
      
    } catch (e, stackTrace) {
      print('❌ ERROR saving to Firestore:');
      print('   Error: $e');
      print('   Type: ${e.runtimeType}');
      print('   Stack trace: $stackTrace');
      
      // Check specific error types
      if (e.toString().contains('permission-denied')) {
        print('🔒 PERMISSION DENIED: Check Firestore security rules');
      } else if (e.toString().contains('unavailable')) {
        print('🌐 NETWORK ISSUE: Check internet connection');
      } else if (e.toString().contains('timeout')) {
        print('⏰ TIMEOUT: Firestore operation took too long');
      }
      
      return false;
    }
  }

  // Remove favorite quote from Firestore with debugging
  Future<bool> removeFavoriteQuote(String quoteId) async {
    print('🔥 FIRESTORE DEBUG: Starting removeFavoriteQuote');
    
    if (_userId == null) {
      print('❌ ERROR: User not authenticated');
      return false;
    }
    
    print('✅ User authenticated: $_userId');
    print('🗑️ Removing quote: $quoteId');
    
    try {
      final docRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc(quoteId);
      
      print('📍 Document path: users/$_userId/favorites/$quoteId');
      
      await docRef.delete().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Firestore delete timeout after 10 seconds');
        },
      );
      
      print('✅ SUCCESS: Quote removed from Firestore');
      return true;
      
    } catch (e, stackTrace) {
      print('❌ ERROR removing from Firestore:');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
      return false;
    }
  }

  // Get all favorite quotes from Firestore with debugging
  Future<List<QuoteModel>> getFavoriteQuotes() async {
    print('🔥 FIRESTORE DEBUG: Starting getFavoriteQuotes');
    
    if (_userId == null) {
      print('❌ ERROR: User not authenticated');
      return [];
    }
    
    print('✅ User authenticated: $_userId');
    
    try {
      print('📖 Reading favorites from Firestore...');
      
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Firestore read timeout after 10 seconds');
        },
      );

      print('📊 Found ${snapshot.docs.length} favorite quotes');
      
      final favorites = snapshot.docs.map((doc) {
        final data = doc.data();
        print('📄 Document ${doc.id}: $data');
        
        return QuoteModel(
          id: data['id'] ?? doc.id,
          text: data['text'] ?? '',
          author: data['author'] ?? 'Unknown',
          isFavorite: true,
        );
      }).toList();
      
      print('✅ SUCCESS: Loaded ${favorites.length} favorites');
      return favorites;
      
    } catch (e, stackTrace) {
      print('❌ ERROR getting favorites from Firestore:');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
      return [];
    }
  }

  // Check if a quote is favorited with debugging
  Future<bool> isQuoteFavorited(String quoteId) async {
    if (_userId == null) return false;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc(quoteId)
          .get()
          .timeout(const Duration(seconds: 5));
      
      final exists = doc.exists;
      print('🔍 Quote $quoteId favorited: $exists');
      return exists;
      
    } catch (e) {
      print('❌ Error checking favorite status: $e');
      return false;
    }
  }

  // Test Firestore connection and permissions
  Future<void> testFirestoreConnection() async {
    print('🧪 TESTING FIRESTORE CONNECTION...');
    
    if (_userId == null) {
      print('❌ No user logged in for test');
      return;
    }
    
    try {
      // Test 1: Check if we can read from Firestore
      print('📖 Test 1: Reading user document...');
      final userDoc = await _firestore.collection('users').doc(_userId).get();
      print('✅ User document exists: ${userDoc.exists}');
      
      // Test 2: Try to write a test document
      print('📝 Test 2: Writing test document...');
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('test')
          .doc('connection_test')
          .set({
        'timestamp': FieldValue.serverTimestamp(),
        'test': true,
        'userId': _userId,
      });
      print('✅ Test write successful');
      
      // Test 3: Read the test document back
      print('📖 Test 3: Reading test document back...');
      final testDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('test')
          .doc('connection_test')
          .get();
      print('✅ Test read successful: ${testDoc.exists}');
      print('📄 Test data: ${testDoc.data()}');
      
      // Test 4: Delete the test document
      print('🗑️ Test 4: Cleaning up test document...');
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('test')
          .doc('connection_test')
          .delete();
      print('✅ Test cleanup successful');
      
      print('🎉 ALL FIRESTORE TESTS PASSED!');
      
    } catch (e, stackTrace) {
      print('❌ FIRESTORE TEST FAILED:');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
      
      // Provide specific guidance based on error
      if (e.toString().contains('permission-denied')) {
        print('');
        print('🔒 PERMISSION DENIED - Possible solutions:');
        print('1. Check Firestore Security Rules');
        print('2. Make sure user is authenticated');
        print('3. Verify rules allow read/write for authenticated users');
      } else if (e.toString().contains('unavailable')) {
        print('');
        print('🌐 FIRESTORE UNAVAILABLE - Possible solutions:');
        print('1. Check internet connection');
        print('2. Verify Firebase project is active');
        print('3. Check if Firestore is enabled in Firebase Console');
      }
    }
  }

  // Get Firestore debug info
  Map<String, dynamic> getDebugInfo() {
    return {
      'userId': _userId,
      'isAuthenticated': _userId != null,
      'currentUser': _auth.currentUser?.email,
      'firestoreApp': _firestore.app.name,
    };
  }
}
