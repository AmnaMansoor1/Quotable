import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  // Test Ad Units (always work) - we'll use these first to verify setup
  static String get testBannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Test banner
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Test banner
    }
    return '';
  }

  static String get testInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test interstitial
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test interstitial
    }
    return '';
  }

  static String get testRewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Test rewarded
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // Test rewarded
    }
    return '';
  }

  // Your actual Ad Units
  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    
    // Use test ads in debug mode, real ads in release mode
    if (kDebugMode) {
      return testBannerAdUnitId;
    }
    
    if (Platform.isAndroid) {
      return 'ca-app-pub-8679980713665486/2477594683'; // Your banner ad unit ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Your iOS banner ID
    } else {
      return '';
    }
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) return '';
    
    // Use test ads in debug mode, real ads in release mode
    if (kDebugMode) {
      return testInterstitialAdUnitId;
    }
    
    if (Platform.isAndroid) {
      return 'ca-app-pub-8679980713665486/3908180134'; // Your interstitial ad unit ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Your iOS interstitial ID
    } else {
      return '';
    }
  }

  static String get rewardedAdUnitId {
    if (kIsWeb) return '';
    
    // Use test ads in debug mode, real ads in release mode
    if (kDebugMode) {
      return testRewardedAdUnitId;
    }
    
    if (Platform.isAndroid) {
      return 'ca-app-pub-8679980713665486/8814405342'; // Your rewarded ad unit ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // Your iOS rewarded ID
    } else {
      return '';
    }
  }

  // App ID
  static String get appId {
    if (kIsWeb) return '';
    
    if (Platform.isAndroid) {
      return 'ca-app-pub-8679980713665486~6288847182'; // Your app ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544~1458002511'; // Test app ID for iOS
    } else {
      return '';
    }
  }

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    if (kIsWeb) {
      print('❌ AdMob not supported on web platform');
      return;
    }
    
    try {
      print('🚀 Starting AdMob initialization...');
      print('📱 Platform: ${Platform.operatingSystem}');
      print('🆔 App ID: ${appId}');
      print('🎯 Banner ID: ${bannerAdUnitId}');
      print('🎯 Interstitial ID: ${interstitialAdUnitId}');
      print('🎯 Rewarded ID: ${rewardedAdUnitId}');
      print('🐛 Debug Mode: $kDebugMode');
      
      // Initialize MobileAds
      final initFuture = MobileAds.instance.initialize();
      
      // Set request configuration
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
          testDeviceIds: kDebugMode ? [] : [], // Add your test device ID here if needed
        ),
      );
      
      // Wait for initialization
      final initStatus = await initFuture;
      
      print('✅ AdMob initialization completed');
      print('📊 Adapter statuses:');
      initStatus.adapterStatuses.forEach((key, value) {
        print('  $key: ${value.state} - ${value.description}');
      });
      
      _isInitialized = true;
      print('🎉 AdMob ready for ads!');
      
    } catch (e, stackTrace) {
      print('❌ Error initializing AdMob: $e');
      print('📍 Stack trace: $stackTrace');
      _isInitialized = false;
    }
  }

  // Check if ads are supported on current platform
  static bool get isSupported {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  // Get ad request with better configuration
  static AdRequest getAdRequest() {
    return const AdRequest(
      keywords: ['quotes', 'inspiration', 'motivation', 'lifestyle'],
      nonPersonalizedAds: false,
    );
  }

  // Debug method to test ad loading
  static Future<void> testAdLoading() async {
    if (!isSupported || !isInitialized) {
      print('❌ Cannot test ads - not supported or not initialized');
      return;
    }

    print('🧪 Testing ad loading...');
    
    // Test banner ad
    try {
      final bannerAd = BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.banner,
        request: getAdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            print('✅ Test banner ad loaded successfully');
            ad.dispose();
          },
          onAdFailedToLoad: (ad, error) {
            print('❌ Test banner ad failed: ${error.message}');
            ad.dispose();
          },
        ),
      );
      bannerAd.load();
    } catch (e) {
      print('❌ Error testing banner ad: $e');
    }
  }
}
