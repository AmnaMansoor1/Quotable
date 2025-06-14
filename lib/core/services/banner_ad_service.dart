import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'admob_service.dart';
import '../config/app_colors.dart';

class BannerAdService extends StatefulWidget {
  final AdSize adSize;
  final bool showDebugInfo;
  
  const BannerAdService({
    super.key,
    this.adSize = AdSize.banner,
    this.showDebugInfo = false,
  });

  @override
  State<BannerAdService> createState() => _BannerAdServiceState();
}

class _BannerAdServiceState extends State<BannerAdService> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdFailed = false;
  bool _isLoading = false;
  String _errorMessage = '';
  String _debugInfo = '';
  int _loadAttempts = 0;
  static const int _maxFailedLoadAttempts = 3;

  @override
  void initState() {
    super.initState();
    _debugInfo = 'Initializing...';
    _checkAndLoadAd();
  }

  void _checkAndLoadAd() {
    _updateDebugInfo('Checking AdMob status...');
    
    if (!AdMobService.isSupported) {
      _updateDebugInfo('Platform not supported');
      setState(() {
        _isAdFailed = true;
        _errorMessage = 'Ads not supported on this platform';
      });
      return;
    }

    if (!AdMobService.isInitialized) {
      _updateDebugInfo('Waiting for AdMob initialization...');
      // Wait for AdMob to initialize
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          if (AdMobService.isInitialized) {
            _updateDebugInfo('AdMob initialized, loading ad...');
            _loadBannerAd();
          } else {
            _updateDebugInfo('AdMob still not initialized, retrying...');
            _checkAndLoadAd();
          }
        }
      });
      return;
    }

    _loadBannerAd();
  }

  void _updateDebugInfo(String info) {
    if (widget.showDebugInfo) {
      setState(() {
        _debugInfo = info;
      });
      print('🎯 Banner Ad Debug: $info');
    }
  }

  void _loadBannerAd() {
    if (_loadAttempts >= _maxFailedLoadAttempts) {
      _updateDebugInfo('Max attempts reached');
      setState(() {
        _isAdFailed = true;
        _errorMessage = 'Max load attempts reached';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isAdFailed = false;
    });

    _loadAttempts++;
    final adUnitId = AdMobService.bannerAdUnitId;
    
    _updateDebugInfo('Loading ad (attempt $_loadAttempts)...');
    print('🎯 Loading banner ad with ID: $adUnitId');

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: widget.adSize,
      request: AdMobService.getAdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('✅ Banner ad loaded successfully!');
          _updateDebugInfo('Ad loaded successfully!');
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
              _isAdFailed = false;
              _isLoading = false;
              _errorMessage = '';
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ Banner ad failed to load:');
          print('   Code: ${error.code}');
          print('   Domain: ${error.domain}');
          print('   Message: ${error.message}');
          
          _updateDebugInfo('Failed: ${error.message}');
          
          ad.dispose();
          _bannerAd = null;
          
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            
            if (_loadAttempts < _maxFailedLoadAttempts) {
              _updateDebugInfo('Retrying in 2 seconds...');
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) _loadBannerAd();
              });
            } else {
              setState(() {
                _isAdFailed = true;
                _errorMessage = 'Failed: ${error.message}';
              });
            }
          }
        },
        onAdOpened: (ad) {
          print('📱 Banner ad opened');
          _updateDebugInfo('Ad opened');
        },
        onAdClosed: (ad) {
          print('❌ Banner ad closed');
          _updateDebugInfo('Ad closed');
        },
        onAdClicked: (ad) {
          print('👆 Banner ad clicked');
          _updateDebugInfo('Ad clicked');
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    print('🗑️ Disposing banner ad...');
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show actual ad if loaded
    if (_isAdLoaded && _bannerAd != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: _bannerAd!.size.height.toDouble(),
            width: double.infinity,
            alignment: Alignment.center,
            child: AdWidget(ad: _bannerAd!),
          ),
          if (widget.showDebugInfo)
            Container(
              padding: const EdgeInsets.all(4),
              color: Colors.green.withOpacity(0.2),
              child: Text(
                'Ad Loaded: $_debugInfo',
                style: const TextStyle(fontSize: 10, color: Colors.green),
              ),
            ),
        ],
      );
    }

    // Show loading state
    if (_isLoading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 50,
            color: AppColors.adPlaceholderBackground,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Loading Ad... (${_loadAttempts}/$_maxFailedLoadAttempts)',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          if (widget.showDebugInfo)
            Container(
              padding: const EdgeInsets.all(4),
              color: Colors.orange.withOpacity(0.2),
              child: Text(
                'Debug: $_debugInfo',
                style: const TextStyle(fontSize: 10, color: Colors.orange),
              ),
            ),
        ],
      );
    }

    // Show error or placeholder
    String message = 'Advertisement Space';
    Color bgColor = AppColors.adPlaceholderBackground;
    Color textColor = AppColors.adPlaceholderText;
    
    if (_isAdFailed) {
      if (_errorMessage.isNotEmpty) {
        message = 'Ad Error: $_errorMessage';
      } else if (!AdMobService.isSupported) {
        message = 'Ads not supported on this platform';
      } else if (!AdMobService.isInitialized) {
        message = 'AdMob not initialized';
      }
      bgColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 50,
          color: bgColor,
          alignment: Alignment.center,
          child: Text(
            message,
            style: TextStyle(color: textColor, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        if (widget.showDebugInfo)
          Container(
            padding: const EdgeInsets.all(4),
            color: Colors.red.withOpacity(0.2),
            child: Column(
              children: [
                Text(
                  'Debug: $_debugInfo',
                  style: const TextStyle(fontSize: 10, color: Colors.red),
                ),
                Text(
                  'Supported: ${AdMobService.isSupported}',
                  style: const TextStyle(fontSize: 10, color: Colors.red),
                ),
                Text(
                  'Initialized: ${AdMobService.isInitialized}',
                  style: const TextStyle(fontSize: 10, color: Colors.red),
                ),
                Text(
                  'Ad Unit: ${AdMobService.bannerAdUnitId}',
                  style: const TextStyle(fontSize: 10, color: Colors.red),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
