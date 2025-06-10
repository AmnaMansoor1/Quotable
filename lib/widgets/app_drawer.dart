import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/config/app_colors.dart';
import '../../features/quotes/screens/quote_of_day_screen.dart';
import '../../features/quotes/screens/favorites_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Drawer(
      backgroundColor: AppColors.drawerBackground,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          SizedBox(
            height: 180,
            child: DrawerHeader(
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: AppColors.drawerBackground.withOpacity(0.85),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Quoteable',
                      style: TextStyle(
                        color: AppColors.drawerHeaderTextColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (user?.email != null)
                      Text(
                        user!.email!,
                        style: TextStyle(
                          color: AppColors.drawerHeaderTextColor.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildDrawerItem(
            context: context,
            icon: Icons.home_outlined,
            text: 'Home',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.favorite_border,
            text: 'Favorite Quotes',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.lightbulb_outline,
            text: 'Quote of the Day',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuoteOfDayScreen()),
              );
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.refresh_outlined,
            text: 'Latest Quotes',
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to latest quotes screen
            },
          ),
          const Divider(color: AppColors.drawerDividerColor, indent: 16, endIndent: 16, height: 16),
          _buildDrawerItem(
            context: context,
            icon: Icons.mail_outline,
            text: 'Contact Us',
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to contact screen
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.shield_outlined,
            text: 'Privacy Policy',
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to privacy policy screen
            },
          ),
          const Divider(color: AppColors.drawerDividerColor, indent: 16, endIndent: 16, height: 16),
          _buildDrawerItem(
            context: context,
            icon: Icons.logout,
            text: 'Sign Out',
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    required GestureTapCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: <Widget>[
              Icon(icon, color: AppColors.drawerIconColor, size: 22),
              const SizedBox(width: 24),
              Text(text, style: const TextStyle(color: AppColors.drawerTextColor, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
