import 'package:flutter/material.dart';
import '../../../core/config/app_colors.dart';
import '../../../models/quote_model.dart';
import '../../../widgets/quote_display_card.dart';
import '../../../core/services/quote_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final QuoteService _quoteService = QuoteService();
  List<QuoteModel> _favoriteQuotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final favorites = await _quoteService.getFavoriteQuotes();
      setState(() {
        _favoriteQuotes = favorites;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading favorites: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onFavoriteChanged() {
    // Reload favorites when a quote is unfavorited
    _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Quotes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavorites,
            tooltip: 'Refresh favorites',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _favoriteQuotes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No favorite quotes yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start adding quotes to your favorites!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadFavorites,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _favoriteQuotes.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == _favoriteQuotes.length - 1 ? 0 : 12.0,
                          ),
                          child: QuoteDisplayCard(
                            quote: _favoriteQuotes[index],
                            onFavoriteChanged: _onFavoriteChanged,
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
