import 'package:flutter/material.dart';
import '../../../core/config/app_colors.dart';
import '../../../models/quote_model.dart';
import '../../../widgets/quote_display_card.dart';
import '../../../core/services/quote_service.dart';

class QuoteOfDayScreen extends StatefulWidget {
  const QuoteOfDayScreen({super.key});

  @override
  State<QuoteOfDayScreen> createState() => _QuoteOfDayScreenState();
}

class _QuoteOfDayScreenState extends State<QuoteOfDayScreen> {
  late Future<QuoteModel> _quoteFuture;
  final QuoteService _quoteService = QuoteService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadQuoteOfDay();
  }

  Future<void> _loadQuoteOfDay() async {
    setState(() {
      _isLoading = true;
      _quoteFuture = _quoteService.getRandomQuote();
    });
    
    // Set loading to false after quote is loaded
    _quoteFuture.then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote of the Day'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<QuoteModel>(
            future: _quoteFuture,
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
                        'Could not load quote of the day',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadQuoteOfDay,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData) {
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
                      const Text(
                        'No quote available',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadQuoteOfDay,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                );
              }
              
              final quote = snapshot.data!;
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Today\'s Inspiration',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    QuoteDisplayCard(quote: quote),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _loadQuoteOfDay,
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(_isLoading ? 'Loading...' : 'Get Another Quote'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
