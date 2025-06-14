import 'package:flutter/material.dart';
import '../../../core/services/rewarded_ad_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/config/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class PremiumFeaturesScreen extends StatefulWidget {
  const PremiumFeaturesScreen({super.key});

  @override
  State<PremiumFeaturesScreen> createState() => _PremiumFeaturesScreenState();
}

class _PremiumFeaturesScreenState extends State<PremiumFeaturesScreen> {
  bool _isLoading = true;
  int _premiumQuotesUnlocked = 0;
  bool _customThemesUnlocked = false;
  bool _adFreeExperience = false;

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
    RewardedAdService.loadRewardedAd();
  }

  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    setState(() {
      _premiumQuotesUnlocked = prefs.getInt('premium_quotes_unlocked') ?? 0;
      _customThemesUnlocked = themeService.customThemesUnlocked;
      _adFreeExperience = prefs.getBool('ad_free_experience') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _savePremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('premium_quotes_unlocked', _premiumQuotesUnlocked);
    await prefs.setBool('ad_free_experience', _adFreeExperience);
  }

  void _showRewardedAd(String feature) {
    if (!RewardedAdService.isAdLoaded) {
      _showMessage('Ad not ready yet. Please try again later.');
      RewardedAdService.loadRewardedAd();
      return;
    }

    RewardedAdService.showRewardedAd(
      onUserEarnedReward: (reward) async {
        final themeService = Provider.of<ThemeService>(context, listen: false);
        
        // Handle different rewards based on feature
        switch (feature) {
          case 'quotes':
            setState(() {
              _premiumQuotesUnlocked += 10;
            });
            _showMessage('You unlocked 10 premium quotes!');
            break;
          case 'themes_unlock':
            await themeService.unlockCustomThemes();
            setState(() {
              _customThemesUnlocked = true;
            });
            _showMessage('Custom themes unlocked! You can now change themes by watching ads.');
            break;
          case 'theme_change':
            await themeService.applyThemeChange();
            _showMessage('Theme changed successfully!');
            break;
          case 'ad_free':
            setState(() {
              _adFreeExperience = true;
            });
            _showMessage('Ad-free experience unlocked for 24 hours!');
            // Schedule to reset after 24 hours
            Future.delayed(const Duration(hours: 24), () {
              if (mounted) {
                setState(() {
                  _adFreeExperience = false;
                });
                _savePremiumStatus();
              }
            });
            break;
        }
        _savePremiumStatus();
      },
      onAdClosed: () {
        // Reload ad for next time
        RewardedAdService.loadRewardedAd();
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Premium Features')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Features'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Unlock Premium Features',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Watch ads to unlock premium features',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Premium Quotes Feature
          _buildFeatureCard(
            title: 'Premium Quotes',
            description: 'Unlock exclusive quotes not available in the free version',
            icon: Icons.auto_awesome,
            color: Colors.amber,
            status: _premiumQuotesUnlocked > 0 
                ? '$_premiumQuotesUnlocked quotes unlocked'
                : 'Not unlocked',
            buttonText: 'Watch Ad to Unlock 10 Quotes',
            onPressed: () => _showRewardedAd('quotes'),
          ),
          
          const SizedBox(height: 16),
          
          // Custom Themes Feature
          _buildCustomThemeCard(),
          
          const SizedBox(height: 16),
          
          // Ad-Free Experience
          _buildFeatureCard(
            title: 'Ad-Free Experience',
            description: 'Enjoy the app without ads for 24 hours',
            icon: Icons.block,
            color: Colors.green,
            status: _adFreeExperience ? 'Active for 24 hours' : 'Not active',
            buttonText: _adFreeExperience 
                ? 'Already Active'
                : 'Watch Ad to Activate',
            onPressed: _adFreeExperience ? null : () => _showRewardedAd('ad_free'),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomThemeCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.color_lens, color: Colors.purple, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Custom Themes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Consumer<ThemeService>(
                        builder: (context, themeService, child) {
                          return Text(
                            _customThemesUnlocked 
                                ? 'Unlocked (${themeService.themeChangesCount} changes)'
                                : 'Not unlocked',
                            style: TextStyle(
                              color: _customThemesUnlocked ? Colors.green : Colors.grey,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Personalize your app with custom color themes. Watch an ad each time you want to change themes.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (_customThemesUnlocked) ...[
              // Theme change controls (requires ad for each change)
              Consumer<ThemeService>(
                builder: (context, themeService, child) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Current Theme: ${themeService.currentThemeName}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: themeService.isDarkMode 
                                  ? () => _showRewardedAd('theme_change')
                                  : null,
                              icon: const Icon(Icons.light_mode),
                              label: const Text('Light Theme'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: !themeService.isDarkMode 
                                    ? Colors.green 
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: !themeService.isDarkMode 
                                  ? () => _showRewardedAd('theme_change')
                                  : null,
                              icon: const Icon(Icons.dark_mode),
                              label: const Text('Dark Theme'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeService.isDarkMode 
                                    ? Colors.green 
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '💡 Watch an ad to change theme',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showRewardedAd('themes_unlock'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.quoteCardBackground,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Watch Ad to Unlock Themes'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String status,
    required String buttonText,
    required VoidCallback? onPressed,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status,
                        style: TextStyle(
                          color: status.contains('Not') ? Colors.grey : Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: onPressed == null ? Colors.grey : AppColors.quoteCardBackground,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
