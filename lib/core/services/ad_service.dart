import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';

/// Central AdMob manager. A singleton (not a widget-tree provider) so the Flame
/// game and any screen can trigger ads without plumbing a ref around — mirrors
/// [AudioService].
///
/// ## Format policy (see [AdConfig])
///  * **Rewarded** — always opt-in, drives most revenue. Never gated by
///    [adsRemoved] (a "remove ads" purchase should still let players earn
///    bonuses). Used for +1 shot, double coins, double daily reward.
///  * **Interstitial** — full-screen, shown only on level *exit* (retry /
///    quit), capped to one per [AdConfig.interstitialEveryNLevels] exits AND
///    [AdConfig.interstitialMinInterval]. Never on level start or "Next".
///  * **App Open** — shown on returning to the app, capped by
///    [AdConfig.appOpenMinInterval] with a launch grace period.
///
/// Every call is fail-safe: an ad problem must never interrupt gameplay, so
/// load/show failures are swallowed and the caller proceeds as if no ad ran.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  /// Set true once a future "Remove Ads" IAP is purchased. Disables the
  /// interruptive formats (interstitial + app open); rewarded stays available.
  static bool adsRemoved = false;

  bool _initialized = false;

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  AppOpenAd? _appOpenAd;

  /// Guards against showing two full-screen ads at once (e.g. an App Open ad
  /// firing on resume while an interstitial is already up).
  bool _showingFullScreenAd = false;

  /// Interstitial pacing state.
  int _levelExitsSinceInterstitial = 0;
  DateTime? _lastInterstitialAt;

  /// App Open pacing state. Seeded to "now" so the very first launch is in the
  /// grace period and won't greet a new player with an ad.
  DateTime? _lastAppOpenAt;

  /// Initialise the SDK and warm up the interruptive formats. Fail-safe: if the
  /// SDK can't start (no Play Services, offline, …) ads are simply absent.
  Future<void> init() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _lastAppOpenAt = DateTime.now();
      _loadRewarded();
      _loadInterstitial();
      _loadAppOpen();
    } catch (_) {
      _initialized = false;
    }
  }

  // --- Rewarded --------------------------------------------------------------

  void _loadRewarded() {
    if (!_initialized || _rewardedAd != null) return;
    RewardedAd.load(
      adUnitId: AdConfig.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (_) => _rewardedAd = null,
      ),
    );
  }

  /// True if a rewarded ad is loaded and ready to show right now — lets the UI
  /// only offer the reward button when it can actually be honoured.
  bool get isRewardedReady => _rewardedAd != null;

  /// Shows the rewarded ad and resolves to `true` only if the user earned the
  /// reward (watched enough). Resolves `false` if no ad was ready or it was
  /// dismissed early — callers must not grant the reward on `false`.
  Future<bool> showRewarded() async {
    final ad = _rewardedAd;
    if (ad == null) {
      _loadRewarded(); // nothing to show now; warm one up for next time.
      return false;
    }
    _rewardedAd = null; // consumed — a fullscreen ad can only be shown once.

    final completer = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _showingFullScreenAd = true,
      onAdDismissedFullScreenContent: (ad) {
        _showingFullScreenAd = false;
        ad.dispose();
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        _showingFullScreenAd = false;
        ad.dispose();
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    await ad.show(onUserEarnedReward: (ad, reward) => earned = true);
    return completer.future;
  }

  // --- Interstitial ----------------------------------------------------------

  void _loadInterstitial() {
    if (!_initialized || adsRemoved || _interstitialAd != null) return;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  /// Call on every level *exit* (retry or quit-to-menu — never on "Next").
  /// Shows an interstitial only when both the level-count and time-interval
  /// caps allow it; otherwise it just advances the counter and returns.
  Future<void> maybeShowInterstitialOnLevelExit() async {
    if (!_initialized || adsRemoved || _showingFullScreenAd) return;
    _levelExitsSinceInterstitial++;

    if (_levelExitsSinceInterstitial < AdConfig.interstitialEveryNLevels) {
      return;
    }
    final last = _lastInterstitialAt;
    if (last != null &&
        DateTime.now().difference(last) < AdConfig.interstitialMinInterval) {
      return;
    }
    final ad = _interstitialAd;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitialAd = null;
    _levelExitsSinceInterstitial = 0;
    _lastInterstitialAt = DateTime.now();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _showingFullScreenAd = true,
      onAdDismissedFullScreenContent: (ad) {
        _showingFullScreenAd = false;
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        _showingFullScreenAd = false;
        ad.dispose();
        _loadInterstitial();
      },
    );
    await ad.show();
  }

  // --- App Open --------------------------------------------------------------

  void _loadAppOpen() {
    if (!_initialized || adsRemoved || _appOpenAd != null) return;
    AppOpenAd.load(
      adUnitId: AdConfig.appOpenUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) => _appOpenAd = ad,
        onAdFailedToLoad: (_) => _appOpenAd = null,
      ),
    );
  }

  /// Show an App Open ad if the interval cap allows and no other full-screen ad
  /// is up. Intended for foreground resumes. Silently does nothing otherwise.
  Future<void> showAppOpenIfAvailable() async {
    if (!_initialized || adsRemoved || _showingFullScreenAd) return;
    final last = _lastAppOpenAt;
    if (last != null &&
        DateTime.now().difference(last) < AdConfig.appOpenMinInterval) {
      return;
    }
    final ad = _appOpenAd;
    if (ad == null) {
      _loadAppOpen();
      return;
    }
    _appOpenAd = null;
    _lastAppOpenAt = DateTime.now();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _showingFullScreenAd = true,
      onAdDismissedFullScreenContent: (ad) {
        _showingFullScreenAd = false;
        ad.dispose();
        _loadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        _showingFullScreenAd = false;
        ad.dispose();
        _loadAppOpen();
      },
    );
    await ad.show();
  }

  /// Frees any loaded ads. Called if the app is being torn down.
  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    _appOpenAd?.dispose();
    _rewardedAd = null;
    _interstitialAd = null;
    _appOpenAd = null;
  }
}
