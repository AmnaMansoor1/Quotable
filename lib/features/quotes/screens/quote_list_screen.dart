import 'package:flutter/material.dart';
import '../../../core/config/app_colors.dart';
import '../../../models/quote_model.dart';
import '../../../widgets/quote_display_card.dart';
import '../../../core/services/quote_service.dart';

class QuotesListScreen extends StatefulWidget {
  final String categoryName;
  final String apiCategoryId;

  const QuotesListScreen({
    super.key,
    required this.categoryName,
    required this.apiCategoryId,
  });

  @override
  State<QuotesListScreen> createState() => _QuotesListScreenState();
}

class _QuotesListScreenState extends State<QuotesListScreen> {
  late Future<List<QuoteModel>> _quotesFuture;
  final QuoteService _quoteService = QuoteService();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    setState(() {
      _quotesFuture = _quoteService.getQuotesByCategory(widget.apiCategoryId);
    });
  }

  Future<void> _refreshQuotes() async {
    setState(() {
      _isRefreshing = true;
    });
    
    await _loadQuotes();
    
    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshQuotes,
            tooltip: 'Refresh quotes',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<QuoteModel>>(
                future: _quotesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading quotes',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadQuotes,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.format_quote,
                            color: Colors.grey[400],
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No quotes found for "${widget.categoryName}"',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadQuotes,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final quotes = snapshot.data!;
                  return RefreshIndicator(
                    onRefresh: _refreshQuotes,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: quotes.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == quotes.length - 1 ? 0 : 12.0,
                          ),
                          child: QuoteDisplayCard(quote: quotes[index]),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            Container(
              height: 50,
              color: AppColors.adPlaceholderBackground,
              alignment: Alignment.center,
              child: const Text(
                "AdMob Banner Ad Placeholder",
                style: TextStyle(color: AppColors.adPlaceholderText, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

