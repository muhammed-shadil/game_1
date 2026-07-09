import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Central AdMob configuration: which ad unit ids to use and the frequency
/// caps that keep ads from harming the play experience.
///
/// ## Test vs. real ids
///
/// While [useTestAds] is true every placement resolves to Google's official
/// *test* ad unit ids, which always fill and never risk your AdMob account.
/// Flip [useTestAds] to false (or ship a release build — see below) and the
/// real ids are used instead.
///
/// IMPORTANT: never run real ads on your own device during development —
/// clicking your own live ads can get the account suspended. Keep test ads on
/// in debug, and add your test device id in [AdService] when testing release.
class AdConfig {
  const AdConfig._();

  /// Master switch. We force test ads in debug/profile builds and only allow
  /// real ids in release, so a stray debug run can never serve live ads.
  static const bool _forceTestInDebug = true;
  static bool get useTestAds => _forceTestInDebug ? !kReleaseMode : false;

  // --- Google's official sample/test ad unit ids -----------------------------
  // https://developers.google.com/admob/flutter/test-ads
  static const String _testRewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedIos =
      'ca-app-pub-3940256099942544/1712485313';
  static const String _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _testAppOpenAndroid =
      'ca-app-pub-3940256099942544/9257395921';
  static const String _testAppOpenIos =
      'ca-app-pub-3940256099942544/5575463023';

  // --- Your real ad unit ids -------------------------------------------------
  // TODO: paste the ids from your AdMob console (Apps -> Ad units). Until then
  // these are left as the test ids so the app still functions if useTestAds is
  // ever forced off before you've created the units.
  static const String _realRewardedAndroid = _testRewardedAndroid;
  static const String _realRewardedIos = _testRewardedIos;
  static const String _realInterstitialAndroid = _testInterstitialAndroid;
  static const String _realInterstitialIos = _testInterstitialIos;
  static const String _realAppOpenAndroid = _testAppOpenAndroid;
  static const String _realAppOpenIos = _testAppOpenIos;

  static bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  static String get rewardedUnitId {
    if (useTestAds) return _isAndroid ? _testRewardedAndroid : _testRewardedIos;
    return _isAndroid ? _realRewardedAndroid : _realRewardedIos;
  }

  static String get interstitialUnitId {
    if (useTestAds) {
      return _isAndroid ? _testInterstitialAndroid : _testInterstitialIos;
    }
    return _isAndroid ? _realInterstitialAndroid : _realInterstitialIos;
  }

  static String get appOpenUnitId {
    if (useTestAds) return _isAndroid ? _testAppOpenAndroid : _testAppOpenIos;
    return _isAndroid ? _realAppOpenAndroid : _realAppOpenIos;
  }

  // --- Frequency caps (tuned for a puzzle game) ------------------------------

  /// Show an interstitial only after at least this many level *exits* (retry or
  /// leave-to-menu) since the last one. Never on level start or "Next".
  static const int interstitialEveryNLevels = 3;

  /// And never sooner than this many seconds after the previous interstitial,
  /// so rapid retries of a hard level don't stack ads.
  static const Duration interstitialMinInterval = Duration(seconds: 90);

  /// Minimum gap between App Open ads, and a grace period after launch so a new
  /// player's first impression is never an ad.
  static const Duration appOpenMinInterval = Duration(minutes: 4);
}
