import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'admob_service.dart';

class RewardedAdService {
  static RewardedAd? _rewardedAd;
  static bool _isAdLoaded = false;
  static int _loadAttempts = 0;
  static const int _maxFailedLoadAttempts = 3;

  static void loadRewardedAd() {
    if (kIsWeb || !AdMobService.isInitialized) {
      print('Rewarded ads not supported on this platform');
      return;
    }
    
    if (_isAdLoaded) {
      print('Rewarded ad already loaded');
      return;
    }
    
    if (_loadAttempts >= _maxFailedLoadAttempts) {
      print('Max load attempts reached for rewarded ad');
      return;
    }

    RewardedAd.load(
      adUnitId: AdMobService.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
          _loadAttempts = 0;
          print('Rewarded ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad failed to load: $error');
          _isAdLoaded = false;
          _loadAttempts++;
          _rewardedAd = null;
          
          if (_loadAttempts < _maxFailedLoadAttempts) {
            loadRewardedAd();
          }
        },
      ),
    );
  }

  static void showRewardedAd({
    required Function(RewardItem reward) onUserEarnedReward,
    VoidCallback? onAdClosed,
  }) {
    if (kIsWeb || !AdMobService.isInitialized) {
      print('Rewarded ads not supported on this platform');
      onAdClosed?.call();
      return;
    }
    
    if (_isAdLoaded && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          print('Rewarded ad showed full screen content');
        },
        onAdDismissedFullScreenContent: (ad) {
          print('Rewarded ad dismissed');
          ad.dispose();
          _isAdLoaded = false;
          _rewardedAd = null;
          onAdClosed?.call();
          // Load next ad
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Rewarded ad failed to show: $error');
          ad.dispose();
          _isAdLoaded = false;
          _rewardedAd = null;
          onAdClosed?.call();
          // Try to load another ad
          loadRewardedAd();
        },
      );

      _rewardedAd!.setImmersiveMode(true);
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          print('User earned reward: ${reward.amount} ${reward.type}');
          onUserEarnedReward(reward);
        },
      );
    } else {
      print('Rewarded ad not ready');
      onAdClosed?.call();
      // Try to load an ad for next time
      loadRewardedAd();
    }
  }

  static bool get isAdLoaded => _isAdLoaded && _rewardedAd != null;

  static void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdLoaded = false;
    _loadAttempts = 0;
  }
}
