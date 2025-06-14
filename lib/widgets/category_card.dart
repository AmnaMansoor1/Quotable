import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../core/services/interstitial_ad_service.dart';
import '../../features/quotes/screens/quote_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryCard extends StatelessWidget {
  final CategoryModel category;

  const CategoryCard({super.key, required this.category});

  Future<bool> _shouldShowAd() async {
    // Check if user has ad-free experience
    final prefs = await SharedPreferences.getInstance();
    final adFreeExperience = prefs.getBool('ad_free_experience') ?? false;
    if (adFreeExperience) {
      print('🚫 Ad-free experience active, skipping ad');
      return false;
    }
    
    // Show ad every 2nd category click (for testing - more frequent)
    final clickCount = prefs.getInt('category_click_count') ?? 0;
    final newClickCount = clickCount + 1;
    await prefs.setInt('category_click_count', newClickCount);
    
    print('📊 Category click count: $newClickCount');
    
    // Show ad every 2nd click
    final shouldShow = newClickCount % 2 == 0;
    print('🎯 Should show ad: $shouldShow (every 2nd click)');
    
    return shouldShow;
  }

  void _navigateToQuotes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuotesListScreen(
          categoryName: category.name,
          apiCategoryId: category.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: category.color,
      borderRadius: BorderRadius.circular(16.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () async {
          print('🎯 Category "${category.name}" clicked');
          
          // Show loading indicator immediately
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );

          final shouldShowAd = await _shouldShowAd();
          
          // Close loading dialog
          if (context.mounted) {
            Navigator.of(context).pop();
          }
          
          if (shouldShowAd) {
            print('🎯 Attempting to show interstitial ad...');
            print('📊 Ad loaded: ${InterstitialAdService.isAdLoaded}');
            
            if (InterstitialAdService.isAdLoaded) {
              print('✅ Showing interstitial ad now!');
              InterstitialAdService.forceShowAd(
                onAdClosed: () {
                  print('✅ Ad closed, navigating to quotes');
                  if (context.mounted) {
                    _navigateToQuotes(context);
                  }
                },
              );
            } else {
              print('⚠️ Ad not loaded, navigating directly');
              if (context.mounted) {
                _navigateToQuotes(context);
              }
              // Try to load ad for next time
              InterstitialAdService.loadInterstitialAd();
            }
          } else {
            print('⏭️ Skipping ad, navigating directly');
            if (context.mounted) {
              _navigateToQuotes(context);
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                category.emoji,
                style: const TextStyle(fontSize: 36.0),
              ),
              const SizedBox(height: 8.0),
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
