import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/config/app_theme.dart';
import 'core/services/notification_service.dart';
import 'core/services/admob_service.dart';
import 'core/services/interstitial_ad_service.dart';
import 'core/services/rewarded_ad_service.dart';
import 'core/services/theme_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/quotes/screens/myhome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print(' Starting app initialization...');
    
    // Initialize Firebase first
    print( ' Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    // Initialize AdMob with detailed logging
    print('📱 Initializing AdMob...');
    await AdMobService.initialize();
    
    if (AdMobService.isInitialized) {
      print('✅ AdMob initialized successfully');
      
      // Test ad loading
      await AdMobService.testAdLoading();
      
      // Load initial ads with delay
      print('🎯 Loading initial ads...');
      Future.delayed(const Duration(seconds: 1), () {
        InterstitialAdService.loadInterstitialAd();
        RewardedAdService.loadRewardedAd();
      });
      
      // Load backup ads
      Future.delayed(const Duration(seconds: 3), () {
        InterstitialAdService.loadInterstitialAd();
        RewardedAdService.loadRewardedAd();
      });
    } else {
      print('❌ AdMob initialization failed');
    }

    // Initialize Notifications
    print('🔔 Initializing Notifications...');
    await NotificationService.initialize();
    
    print('🎉 All services initialized successfully');
  } catch (e, stackTrace) {
    print('❌ Error during initialization: $e');
    print('📍 Stack trace: $stackTrace');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeService()..initialize(),
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Quotable - Inspirational Quotes',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            debugShowCheckedModeBanner: false,
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasData && snapshot.data != null) {
                  return const HomeScreen();
                }

                return const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}

