import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// テスト用広告ID（本番時は実際のIDに差し替え）
class _AdIds {
  static const String _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewarded = 'ca-app-pub-3940256099942544/5224354917';

  // TODO: 本番IDはここに設定
  static const String _prodBanner = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _prodInterstitial = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _prodRewarded = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  static bool get _useTest => kDebugMode;

  static String get banner => _useTest ? _testBanner : _prodBanner;
  static String get interstitial =>
      _useTest ? _testInterstitial : _prodInterstitial;
  static String get rewarded => _useTest ? _testRewarded : _prodRewarded;
}

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  BannerAd? _bannerAd;
  bool _interstitialReady = false;
  bool _rewardedReady = false;

  static Future<void> init() async {
    await MobileAds.instance.initialize();
    AdService()._loadInterstitial();
    AdService()._loadRewarded();
  }

  // ── Banner ──────────────────────────────────────────────

  BannerAd createBanner() {
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: _AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
    return _bannerAd!;
  }

  void disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  // ── Interstitial ─────────────────────────────────────────

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (_) {
              _interstitialReady = false;
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _interstitialReady = false;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _interstitialReady = false;
        },
      ),
    );
  }

  /// ゲームオーバー時に呼ぶ。表示できなければ何もしない。
  Future<void> showInterstitial() async {
    if (_interstitialReady && _interstitialAd != null) {
      await _interstitialAd!.show();
    }
  }

  // ── Rewarded ──────────────────────────────────────────────

  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: _AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (_) {
              _rewardedReady = false;
              _loadRewarded();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _rewardedReady = false;
              _loadRewarded();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _rewardedReady = false;
        },
      ),
    );
  }

  bool get isRewardedReady => _rewardedReady;

  /// リワード広告を表示。報酬を受け取った場合 onRewarded を呼ぶ。
  Future<void> showRewarded({required VoidCallback onRewarded}) async {
    if (!_rewardedReady || _rewardedAd == null) return;
    await _rewardedAd!.show(
      onUserEarnedReward: (_, __) => onRewarded(),
    );
  }

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _bannerAd?.dispose();
  }
}
