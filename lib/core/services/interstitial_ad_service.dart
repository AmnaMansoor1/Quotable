import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admob_service.dart';

class InterstitialAdService {
  static InterstitialAd? _interstitialAd;
  static bool _isAdLoaded = false;
  static int _loadAttempts = 0;
  static const int _maxFailedLoadAttempts = 3;
  static DateTime? _lastAdShown;
  static const int _minTimeBetweenAds = 5; // Reduced to 5 seconds for better testing

  static void loadInterstitialAd() {
    if (kIsWeb || !AdMobService.isSupported) {
      print('❌ Interstitial ads not supported on this platform');
      return;
    }

    if (!AdMobService.isInitialized) {
      print('⏳ AdMob not initialized yet, waiting...');
      Future.delayed(const Duration(seconds: 1), () {
        if (AdMobService.isInitialized) {
          loadInterstitialAd();
        }
      });
      return;
    }
    
    if (_isAdLoaded) {
      print('✅ Interstitial ad already loaded');
      return;
    }
    
    if (_loadAttempts >= _maxFailedLoadAttempts) {
      print('❌ Max load attempts reached for interstitial ad');
      return;
    }

    _loadAttempts++;
    final adUnitId = AdMobService.interstitialAdUnitId;
    
    print('🔄 Loading interstitial ad (attempt $_loadAttempts)...');
    print('🆔 Ad Unit ID: $adUnitId');

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: AdMobService.getAdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          _loadAttempts = 0;
          print('✅ Interstitial ad loaded successfully!');
          
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          print('❌ Interstitial ad failed to load:');
          print('   Code: ${error.code}');
          print('   Domain: ${error.domain}');
          print('   Message: ${error.message}');
          
          _isAdLoaded = false;
          _interstitialAd = null;
          
          // Retry loading after a delay
          if (_loadAttempts < _maxFailedLoadAttempts) {
            print('🔄 Retrying interstitial ad load in 3 seconds...');
            Future.delayed(const Duration(seconds: 3), () {
              loadInterstitialAd();
            });
          } else {
            print('❌ Giving up on interstitial ad loading');
          }
        },
      ),
    );
  }

  static void showInterstitialAd({VoidCallback? onAdClosed}) {
    if (kIsWeb || !AdMobService.isSupported) {
      print('❌ Interstitial ads not supported');
      onAdClosed?.call();
      return;
    }

    if (!AdMobService.isInitialized) {
      print('❌ AdMob not initialized');
      onAdClosed?.call();
      return;
    }

    // Check if enough time has passed since last ad
    if (_lastAdShown != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastAdShown!).inSeconds;
      if (timeSinceLastAd < _minTimeBetweenAds) {
        print('⏰ Too soon to show another interstitial ad (${timeSinceLastAd}s < ${_minTimeBetweenAds}s)');
        onAdClosed?.call();
        return;
      }
    }
    
    if (_isAdLoaded && _interstitialAd != null) {
      print('📱 Showing interstitial ad...');
      
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          print('📱 Interstitial ad showed full screen content');
          _lastAdShown = DateTime.now();
        },
        onAdDismissedFullScreenContent: (ad) {
          print('❌ Interstitial ad dismissed');
          ad.dispose();
          _isAdLoaded = false;
          _interstitialAd = null;
          onAdClosed?.call();
          // Load next ad immediately
          print('🔄 Loading next interstitial ad...');
          Future.delayed(const Duration(milliseconds: 500), () {
            loadInterstitialAd();
          });
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('❌ Interstitial ad failed to show: ${error.message}');
          ad.dispose();
          _isAdLoaded = false;
          _interstitialAd = null;
          onAdClosed?.call();
          // Try to load another ad
          Future.delayed(const Duration(milliseconds: 500), () {
            loadInterstitialAd();
          });
        },
      );

      _interstitialAd!.show();
    } else {
      print('⚠️ Interstitial ad not ready');
      print('   Is loaded: $_isAdLoaded');
      print('   Ad object: ${_interstitialAd != null}');
      print('   Load attempts: $_loadAttempts');
      
      onAdClosed?.call();
      // Try to load an ad for next time
      if (!_isAdLoaded) {
        print('🔄 Loading interstitial ad for next time...');
        loadInterstitialAd();
      }
    }
  }

  static bool get isAdLoaded => _isAdLoaded && _interstitialAd != null;

  static void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
    _loadAttempts = 0;
  }

  // Force show ad (for testing) - bypasses time restriction
  static void forceShowAd({VoidCallback? onAdClosed}) {
    print('🧪 Force showing ad (bypassing time restriction)');
    _lastAdShown = null; // Reset timer
    showInterstitialAd(onAdClosed: onAdClosed);
  }

  // Reset click counter (for testing)
  static Future<void> resetClickCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('category_click_count', 0);
    print('🔄 Click counter reset');
  }

  // Debug info
  static Map<String, dynamic> getDebugInfo() {
    return {
      'isAdLoaded': _isAdLoaded,
      'loadAttempts': _loadAttempts,
      'hasAdObject': _interstitialAd != null,
      'lastAdShown': _lastAdShown?.toString(),
      'adUnitId': AdMobService.interstitialAdUnitId,
      'isSupported': AdMobService.isSupported,
      'isInitialized': AdMobService.isInitialized,
      'minTimeBetweenAds': _minTimeBetweenAds,
    };
  }
}
