import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/favorites_service.dart';
import '../../../models/quote_model.dart';

class DebugAuthScreen extends StatefulWidget {
  const DebugAuthScreen({super.key});

  @override
  State<DebugAuthScreen> createState() => _DebugAuthScreenState();
}

class _DebugAuthScreenState extends State<DebugAuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FavoritesService _favoritesService = FavoritesService();
  
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    setState(() => _isLoading = true);
    await _getAllUsers();
    setState(() => _isLoading = false);
  }

  Future<void> _getAllUsers() async {
    try {
      print('🔍 Searching for all users in Firestore...');
      
      // Get all documents in the users collection
      final usersSnapshot = await _firestore.collection('users').get();
      
      print('📊 Found ${usersSnapshot.docs.length} user documents');
      
      final users = <Map<String, dynamic>>[];
      
      for (final userDoc in usersSnapshot.docs) {
        print('👤 Processing user: ${userDoc.id}');
        
        // Get favorites count for each user
        final favoritesSnapshot = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('favorites')
            .get();
        
        final userData = userDoc.data();
        users.add({
          'userId': userDoc.id,
          'email': userData['email'] ?? 'Unknown',
          'createdAt': userData['createdAt']?.toDate()?.toString() ?? 'Unknown',
          'favoritesCount': favoritesSnapshot.docs.length,
          'isCurrentUser': userDoc.id == _auth.currentUser?.uid,
          'userData': userData,
        });
        
        print('   Email: ${userData['email'] ?? 'Not set'}');
        print('   Favorites: ${favoritesSnapshot.docs.length}');
        print('   Is current: ${userDoc.id == _auth.currentUser?.uid}');
      }
      
      setState(() {
        _allUsers = users;
      });
      
    } catch (e, stackTrace) {
      print('❌ Error getting all users: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _createUserDocument() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ No current user');
      return;
    }

    try {
      print('📝 Creating user document for: ${currentUser.uid}');
      
      await _firestore.collection('users').doc(currentUser.uid).set({
        'email': currentUser.email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'uid': currentUser.uid,
      }, SetOptions(merge: true));
      
      print('✅ User document created/updated');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User document created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      _loadDebugInfo();
      
    } catch (e) {
      print('❌ Error creating user document: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating user document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testCurrentUserFavorites() async {
    print('🧪 Testing current user favorites...');
    
    try {
      await _favoritesService.testFirestoreConnection();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firestore test completed - check console logs'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('❌ Error testing Firestore: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firestore test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NEW: Test adding a favorite quote
  Future<void> _testAddFavorite() async {
    print('🧪 Testing add favorite quote...');
    
    try {
      // Create a test quote
      final testQuote = QuoteModel(
        id: 'test_quote_${DateTime.now().millisecondsSinceEpoch}',
        text: 'This is a test quote to verify Firestore favorites functionality.',
        author: 'Debug Test',
        isFavorite: false,
      );
      
      print('📝 Adding test quote: ${testQuote.id}');
      
      // Add to favorites
      final success = await _favoritesService.saveFavoriteQuote(testQuote);
      
      if (success) {
        print('✅ Test quote added successfully!');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Test quote added successfully! Check Firebase Console.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // Refresh the user list to see updated favorites count
        _loadDebugInfo();
      } else {
        print('❌ Failed to add test quote');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add test quote - check console logs'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      
    } catch (e) {
      print('❌ Error testing add favorite: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error testing add favorite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NEW: Get and display current user's favorites
  Future<void> _showCurrentUserFavorites() async {
    print('📖 Getting current user favorites...');
    
    try {
      final favorites = await _favoritesService.getFavoriteQuotes();
      
      print('📊 Found ${favorites.length} favorites');
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Current User Favorites (${favorites.length})'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: favorites.isEmpty
                  ? const Center(child: Text('No favorites found'))
                  : ListView.builder(
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final quote = favorites[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  quote.text,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text('- ${quote.author}'),
                                Text('ID: ${quote.id}', style: const TextStyle(fontSize: 10)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
      
    } catch (e) {
      print('❌ Error getting favorites: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting favorites: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _switchToUser(String userId) async {
    // This is just for debugging - shows what would happen
    print('🔄 Would switch to user: $userId');
    print('⚠️ Note: This is just a debug function');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Debug: Would switch to user $userId'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Authentication'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebugInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current User Info
                  Card(
                    color: Colors.blue.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '👤 CURRENT AUTHENTICATED USER',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('UID: ${currentUser?.uid ?? 'Not logged in'}'),
                          Text('Email: ${currentUser?.email ?? 'No email'}'),
                          Text('Display Name: ${currentUser?.displayName ?? 'No name'}'),
                          Text('Email Verified: ${currentUser?.emailVerified ?? false}'),
                          Text('Created: ${currentUser?.metadata.creationTime?.toString() ?? 'Unknown'}'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton(
                                onPressed: _createUserDocument,
                                child: const Text('Create User Doc'),
                              ),
                              ElevatedButton(
                                onPressed: _testCurrentUserFavorites,
                                child: const Text('Test Connection'),
                              ),
                              ElevatedButton(
                                onPressed: _testAddFavorite,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Add Test Quote'),
                              ),
                              ElevatedButton(
                                onPressed: _showCurrentUserFavorites,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                ),
                                child: const Text('Show Favorites'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // All Users in Firestore
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🔥 ALL USERS IN FIRESTORE (${_allUsers.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          if (_allUsers.isEmpty)
                            const Text(
                              'No users found in Firestore',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ..._allUsers.map((user) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: user['isCurrentUser'] 
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: user['isCurrentUser'] 
                                      ? Colors.green 
                                      : Colors.grey,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        user['isCurrentUser'] 
                                            ? Icons.person 
                                            : Icons.person_outline,
                                        color: user['isCurrentUser'] 
                                            ? Colors.green 
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          user['isCurrentUser'] 
                                              ? 'CURRENT USER ⭐' 
                                              : 'OTHER USER',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: user['isCurrentUser'] 
                                                ? Colors.green 
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                      // Favorites badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8, 
                                          vertical: 4
                                        ),
                                        decoration: BoxDecoration(
                                          color: user['favoritesCount'] > 0 
                                              ? Colors.blue 
                                              : Colors.grey,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '❤️ ${user['favoritesCount']}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('UID: ${user['userId']}'),
                                  Text('Email: ${user['email']}'),
                                  Text('Favorites: ${user['favoritesCount']}'),
                                  Text('Created: ${user['createdAt']}'),
                                  
                                  if (!user['isCurrentUser'])
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: ElevatedButton(
                                        onPressed: () => _switchToUser(user['userId']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                        ),
                                        child: const Text('Debug Switch'),
                                      ),
                                    ),
                                ],
                              ),
                            )).toList(),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Debug Actions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🛠️ DEBUG ACTIONS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _auth.signOut();
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Sign Out'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          ElevatedButton.icon(
                            onPressed: _loadDebugInfo,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh Data'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
