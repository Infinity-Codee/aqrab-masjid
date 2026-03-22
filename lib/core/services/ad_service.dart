import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static final AdService instance = AdService._();

  static const String _androidBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _iosBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716';

  static const String _androidInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _iosInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';

  static const String _androidAppOpenAdUnitId =
      'ca-app-pub-3940256099942544/9257395921';
  static const String _iosAppOpenAdUnitId =
      'ca-app-pub-3940256099942544/5575463023';

  AppOpenAd? _appOpenAd;
  DateTime? _appOpenAdLoadedAt;
  InterstitialAd? _interstitialAd;
  bool _isLoadingAppOpenAd = false;
  bool _isShowingAppOpenAd = false;
  bool _isLoadingInterstitialAd = false;

  bool get isSupportedPlatform {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  String get bannerAdUnitId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidBannerAdUnitId;
      case TargetPlatform.iOS:
        return _iosBannerAdUnitId;
      default:
        throw UnsupportedError('Banner ads are not supported on this platform');
    }
  }

  String get interstitialAdUnitId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidInterstitialAdUnitId;
      case TargetPlatform.iOS:
        return _iosInterstitialAdUnitId;
      default:
        throw UnsupportedError(
          'Interstitial ads are not supported on this platform',
        );
    }
  }

  String get appOpenAdUnitId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidAppOpenAdUnitId;
      case TargetPlatform.iOS:
        return _iosAppOpenAdUnitId;
      default:
        throw UnsupportedError(
          'App open ads are not supported on this platform',
        );
    }
  }

  Future<void> initialize() async {
    if (!isSupportedPlatform) {
      return;
    }

    await MobileAds.instance.initialize();
    loadAppOpenAd();
    loadInterstitialAd();
  }

  BannerAd createBannerAd({
    required VoidCallback onLoaded,
    required void Function(LoadAdError error) onFailed,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailed(error);
        },
      ),
    );
  }

  void loadAppOpenAd() {
    if (!isSupportedPlatform || _isLoadingAppOpenAd || _appOpenAd != null) {
      return;
    }

    _isLoadingAppOpenAd = true;
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenAdLoadedAt = DateTime.now();
          _isLoadingAppOpenAd = false;
        },
        onAdFailedToLoad: (error) {
          _isLoadingAppOpenAd = false;
        },
      ),
    );
  }

  Future<void> showAppOpenAdIfAvailable() async {
    if (!isSupportedPlatform || _isShowingAppOpenAd) {
      return;
    }

    if (!_isAppOpenAdAvailable) {
      loadAppOpenAd();
      return;
    }

    final ad = _appOpenAd!;
    _appOpenAd = null;
    _isShowingAppOpenAd = true;

    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAppOpenAd = false;
        ad.dispose();
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAppOpenAd = false;
        ad.dispose();
        loadAppOpenAd();
      },
    );
    ad.show();
  }

  void loadInterstitialAd() {
    if (!isSupportedPlatform ||
        _isLoadingInterstitialAd ||
        _interstitialAd != null) {
      return;
    }

    _isLoadingInterstitialAd = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoadingInterstitialAd = false;
        },
        onAdFailedToLoad: (error) {
          _isLoadingInterstitialAd = false;
        },
      ),
    );
  }

  Future<void> showInterstitialAd({required VoidCallback onAdComplete}) async {
    if (!isSupportedPlatform) {
      onAdComplete();
      return;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      onAdComplete();
      loadInterstitialAd();
      return;
    }

    _interstitialAd = null;
    var didComplete = false;

    void completeOnce() {
      if (didComplete) {
        return;
      }
      didComplete = true;
      onAdComplete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        completeOnce();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        completeOnce();
        loadInterstitialAd();
      },
    );

    ad.show();
  }

  bool get _isAppOpenAdAvailable {
    final isFresh =
        _appOpenAdLoadedAt != null &&
        DateTime.now().difference(_appOpenAdLoadedAt!) <
            const Duration(hours: 4);
    if (!isFresh) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
    }
    return _appOpenAd != null;
  }

  void dispose() {
    _appOpenAd?.dispose();
    _interstitialAd?.dispose();
    _appOpenAd = null;
    _interstitialAd = null;
  }
}
