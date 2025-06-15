import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'admob_service.dart';

class RewardedAdService {
  static RewardedAd? _rewardedAd;
  static bool _isAdLoaded = false;
  static int _loadAttempts = 0;
  static const int _maxFailedLoadAttempts = 5; // Increased attempts
  static DateTime? _lastLoadAttempt;

  static void loadRewardedAd() {
    if (kIsWeb || !AdMobService.isSupported) {
      print('❌ Rewarded ads not supported on this platform');
      return;
    }

    if (!AdMobService.isInitialized) {
      print('⏳ AdMob not initialized yet, waiting...');
      Future.delayed(const Duration(seconds: 2), () {
        if (AdMobService.isInitialized) {
          loadRewardedAd();
        }
      });
      return;
    }
    
    if (_isAdLoaded) {
      print('✅ Rewarded ad already loaded');
      return;
    }
    
    // Prevent too frequent load attempts
    if (_lastLoadAttempt != null) {
      final timeSinceLastAttempt = DateTime.now().difference(_lastLoadAttempt!);
      if (timeSinceLastAttempt.inSeconds < 5) {
        print('⏰ Too soon to retry loading (${timeSinceLastAttempt.inSeconds}s < 5s)');
        return;
      }
    }
    
    if (_loadAttempts >= _maxFailedLoadAttempts) {
      print('❌ Max load attempts reached for rewarded ad ($_loadAttempts/$_maxFailedLoadAttempts)');
      return;
    }

    _loadAttempts++;
    _lastLoadAttempt = DateTime.now();
    final adUnitId = AdMobService.rewardedAdUnitId;
    
    print('🔄 Loading rewarded ad (attempt $_loadAttempts/$_maxFailedLoadAttempts)...');
    print('🆔 Ad Unit ID: $adUnitId');

    RewardedAd.load(
      adUnitId: adUnitId,
      request: AdMobService.getAdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
          _loadAttempts = 0; // Reset on success
          print('✅ Rewarded ad loaded successfully!');
          
          // Set up ad callbacks
          _rewardedAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          print('❌ Rewarded ad failed to load:');
          print('   Code: ${error.code}');
          print('   Domain: ${error.domain}');
          print('   Message: ${error.message}');
          print('   Attempt: $_loadAttempts/$_maxFailedLoadAttempts');
          
          _isAdLoaded = false;
          _rewardedAd = null;
          
          // Provide specific error guidance
          if (error.code == 3) {
            print('💡 Error code 3: No ad inventory available');
            print('   This is normal in test mode or low ad inventory regions');
          } else if (error.code == 1) {
            print('💡 Error code 1: Invalid request');
            print('   Check ad unit ID and request configuration');
          } else if (error.code == 2) {
            print('💡 Error code 2: Network error');
            print('   Check internet connection');
          }
          
          // Retry loading after a delay if we haven't exceeded max attempts
          if (_loadAttempts < _maxFailedLoadAttempts) {
            final retryDelay = _loadAttempts * 2; // Exponential backoff
            print('🔄 Retrying rewarded ad load in ${retryDelay}s...');
            Future.delayed(Duration(seconds: retryDelay), () {
              loadRewardedAd();
            });
          } else {
            print('❌ Giving up on rewarded ad loading after $_loadAttempts attempts');
          }
        },
      ),
    );
  }

  static void showRewardedAd({
    required Function(RewardItem reward) onUserEarnedReward,
    VoidCallback? onAdClosed,
  }) {
    if (kIsWeb || !AdMobService.isSupported) {
      print('❌ Rewarded ads not supported');
      onAdClosed?.call();
      return;
    }

    if (!AdMobService.isInitialized) {
      print('❌ AdMob not initialized');
      onAdClosed?.call();
      return;
    }
    
    if (_isAdLoaded && _rewardedAd != null) {
      print('📱 Showing rewarded ad...');
      
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          print('📱 Rewarded ad showed full screen content');
        },
        onAdDismissedFullScreenContent: (ad) {
          print('❌ Rewarded ad dismissed');
          ad.dispose();
          _isAdLoaded = false;
          _rewardedAd = null;
          onAdClosed?.call();
          // Load next ad immediately
          print('🔄 Loading next rewarded ad...');
          Future.delayed(const Duration(milliseconds: 500), () {
            loadRewardedAd();
          });
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('❌ Rewarded ad failed to show: ${error.message}');
          ad.dispose();
          _isAdLoaded = false;
          _rewardedAd = null;
          onAdClosed?.call();
          // Try to load another ad
          Future.delayed(const Duration(milliseconds: 500), () {
            loadRewardedAd();
          });
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          print('🎉 User earned reward: ${reward.amount} ${reward.type}');
          onUserEarnedReward(reward);
        },
      );
    } else {
      print('⚠️ Rewarded ad not ready');
      print('   Is loaded: $_isAdLoaded');
      print('   Ad object: ${_rewardedAd != null}');
      print('   Load attempts: $_loadAttempts');
      print('   Max attempts: $_maxFailedLoadAttempts');
      
      onAdClosed?.call();
      // Try to load an ad for next time
      if (!_isAdLoaded && _loadAttempts < _maxFailedLoadAttempts) {
        print('🔄 Loading rewarded ad for next time...');
        loadRewardedAd();
      }
    }
  }

  static bool get isAdLoaded => _isAdLoaded && _rewardedAd != null;

  static void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdLoaded = false;
    _loadAttempts = 0;
    _lastLoadAttempt = null;
  }

  // Reset load attempts (for testing)
  static void resetLoadAttempts() {
    _loadAttempts = 0;
    _lastLoadAttempt = null;
    print('🔄 Rewarded ad load attempts reset');
  }

  // Get debug info
  static Map<String, dynamic> getDebugInfo() {
    return {
      'isAdLoaded': _isAdLoaded,
      'loadAttempts': _loadAttempts,
      'maxAttempts': _maxFailedLoadAttempts,
      'hasAdObject': _rewardedAd != null,
      'lastLoadAttempt': _lastLoadAttempt?.toString(),
      'adUnitId': AdMobService.rewardedAdUnitId,
      'isSupported': AdMobService.isSupported,
      'isInitialized': AdMobService.isInitialized,
    };
  }
}
