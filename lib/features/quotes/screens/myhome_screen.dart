import 'package:flutter/material.dart';
import '../../../core/config/app_colors.dart';
import '../../../models/category_model.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/category_card.dart';
import '../../../widgets/search_bar_widget.dart';
import '../../../widgets/app_logo.dart';
import '../../../core/services/banner_ad_service.dart';

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

  @override
  void initState() {
    super.initState();
    _filteredCategories = _allCategories;
    _searchController.addListener(_filterCategories);
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
        title: Row(
          children: [
            const AppLogo(size: 32, showText: false),
            const SizedBox(width: 12),
            const Text('My Quotable'),
          ],
        ),
        centerTitle: false,
      ),
      drawer: AppDrawer (),
      body: Column(
        children: <Widget>[
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
          // Banner ad at the bottom
          const BannerAdService(),
        ],
      ),
    );
  }
}
