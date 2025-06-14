import 'package:flutter/material.dart';
import '../../../core/config/app_colors.dart';
import '../../../models/category_model.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/category_card.dart';
import '../../../widgets/search_bar_widget.dart';
import '../../../core/services/banner_ad_service.dart';
import '../../../core/services/admob_service.dart';
import '../../../core/services/interstitial_ad_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<CategoryModel> _allCategories = [
    CategoryModel(id: 'alone', name: 'Alone', emoji: '😔', color: AppColors.categoryAlone),
    CategoryModel(id: 'angry', name: 'Angry', emoji: '😠', color: AppColors.categoryAngry),
    CategoryModel(id: 'attitude', name: 'Attitude', emoji: '😎', color: AppColors.categoryAttitude),
    CategoryModel(id: 'breakup', name: 'Breakup', emoji: '💔', color: AppColors.categoryBreakup),
    CategoryModel(id: 'emotional', name: 'Emotional', emoji: '😢', color: AppColors.categoryEmotional),
    CategoryModel(id: 'family', name: 'Family', emoji: '👨‍👩‍👧‍👦', color: AppColors.categoryFamily),
    CategoryModel(id: 'friends', name: 'Friends', emoji: '🧑‍🤝‍🧑', color: Colors.lightBlue.shade200),
    CategoryModel(id: 'funny', name: 'Funny', emoji: '😂', color: Colors.orange.shade200),
    CategoryModel(id: 'love', name: 'Love', emoji: '❤️', color: Colors.pink.shade200),
    CategoryModel(id: 'motivational', name: 'Motivational', emoji: '💪', color: Colors.green.shade200),
    CategoryModel(id: 'success', name: 'Success', emoji: '🏆', color: Colors.amber.shade200),
    CategoryModel(id: 'wisdom', name: 'Wisdom', emoji: '🦉', color: Colors.purple.shade200),
  ];

  List<CategoryModel> _filteredCategories = [];
  final TextEditingController _searchController = TextEditingController();
  bool _showDebugInfo = false;
  int _clickCount = 0;

  @override
  void initState() {
    super.initState();
    _filteredCategories = _allCategories;
    _searchController.addListener(_filterCategories);
    _loadClickCount();
  }

  Future<void> _loadClickCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _clickCount = prefs.getInt('category_click_count') ?? 0;
    });
  }

  void _filterCategories() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() => _filteredCategories = _allCategories);
    } else {
      setState(() {
        _filteredCategories = _allCategories
            .where((category) => category.name.toLowerCase().contains(query))
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCategories);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotable'),
        centerTitle: false,
        actions: [
          // Debug button
          IconButton(
            icon: Icon(_showDebugInfo ? Icons.bug_report : Icons.bug_report_outlined),
            onPressed: () {
              setState(() {
                _showDebugInfo = !_showDebugInfo;
              });
            },
            tooltip: 'Toggle Debug Info',
          ),
          // Test ad button
          IconButton(
            icon: const Icon(Icons.ads_click),
            onPressed: () {
              print('🧪 Testing interstitial ad...');
              final debugInfo = InterstitialAdService.getDebugInfo();
              print('Debug info: $debugInfo');
              InterstitialAdService.forceShowAd();
            },
            tooltip: 'Test Interstitial Ad',
          ),
          // Reset counter button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await InterstitialAdService.resetClickCounter();
              await _loadClickCount();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Click counter reset!')),
              );
            },
            tooltip: 'Reset Click Counter',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: <Widget>[
          // Debug info panel
          if (_showDebugInfo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.blue.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🐛 DEBUG INFO', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('AdMob Supported: ${AdMobService.isSupported}'),
                  Text('AdMob Initialized: ${AdMobService.isInitialized}'),
                  Text('Interstitial Loaded: ${InterstitialAdService.isAdLoaded}'),
                  Text('Click Count: $_clickCount (next ad: ${(_clickCount + 1) % 2 == 0 ? "YES" : "NO"})'),
                  Text('Banner ID: ${AdMobService.bannerAdUnitId}'),
                  Text('Interstitial ID: ${AdMobService.interstitialAdUnitId}'),
                ],
              ),
            ),
          
          SearchBarWidget(
            controller: _searchController,
            hintText: 'Search Category',
          ),
          Expanded(
            child: _filteredCategories.isEmpty && _searchController.text.isNotEmpty
                ? const Center(
                    child: Text(
                      "No categories found.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _filteredCategories.length,
                    itemBuilder: (context, index) {
                      return CategoryCard(category: _filteredCategories[index]);
                    },
                  ),
          ),
          // Banner ad at the bottom with debug info
          BannerAdService(showDebugInfo: _showDebugInfo),
        ],
      ),
    );
  }
}
