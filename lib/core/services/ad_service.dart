import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum RewardedAdResult {
  rewarded,
  dismissedWithoutReward,
  unavailable,
  unsupported,
}

/// Centralized Google AdMob service for Saving Challenge.
///
/// - Automatically uses Google's official test ad unit IDs in debug/profile builds
///   to comply with AdMob invalid-traffic policy.
/// - Switches to the live Android Banner & Rewarded Ad Unit IDs in release builds.
/// - Safely no-ops on Web / Desktop / iOS (until an iOS AdMob App ID is configured).
class AdService {
  AdService._();

  static const String _androidLiveBannerId =
      'ca-app-pub-9661048212416719/8204093844';
  static const String _androidTestBannerId =
      'ca-app-pub-3940256099942544/6300978111';

  static const String _androidLiveRewardedId =
      'ca-app-pub-9661048212416719/3524119401';
  static const String _androidTestRewardedId =
      'ca-app-pub-3940256099942544/5224354917';

  static bool _initialized = false;
  static Future<void>? _initFuture;

  static RewardedAd? _rewardedAd;
  static bool _isLoadingRewarded = false;

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  static bool get isRewardedAdReady => _rewardedAd != null;

  static String get bannerAdUnitId {
    if (kReleaseMode) {
      return _androidLiveBannerId;
    }
    return _androidTestBannerId;
  }

  static String get rewardedAdUnitId {
    if (kReleaseMode) {
      return _androidLiveRewardedId;
    }
    return _androidTestRewardedId;
  }

  /// Initializes the Google Mobile Ads SDK without blocking offline app startup.
  static Future<void> initialize() {
    if (!isSupported || _initialized) return Future.value();
    return _initFuture ??= _doInitialize();
  }

  static Future<void> _doInitialize() async {
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      unawaited(preloadRewardedAd());
    } catch (e) {
      _initFuture = null;
      debugPrint('AdMob initialization skipped/failed (offline-safe): $e');
    }
  }

  /// Preloads a single opt-in RewardedAd in the background so it opens fast when requested.
  static Future<void> preloadRewardedAd() async {
    if (!isSupported || _rewardedAd != null || _isLoadingRewarded) return;
    _isLoadingRewarded = true;
    try {
      await initialize();
      final completer = Completer<void>();
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd?.dispose();
            _rewardedAd = ad;
            _isLoadingRewarded = false;
            if (!completer.isCompleted) completer.complete();
          },
          onAdFailedToLoad: (error) {
            debugPrint(
              'AdMob rewarded preload failed (code ${error.code}): ${error.message}',
            );
            _isLoadingRewarded = false;
            if (!completer.isCompleted) completer.complete();
          },
        ),
      );
      await completer.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          _isLoadingRewarded = false;
        },
      );
    } catch (e) {
      _isLoadingRewarded = false;
      debugPrint('AdMob rewarded preload skipped/failed: $e');
    }
  }

  /// Displays an opt-in RewardedAd and grants the reward ONLY inside [onEarnedReward].
  static Future<RewardedAdResult> showRewardedAd({
    required Future<void> Function(RewardItem reward) onEarnedReward,
  }) async {
    if (!isSupported) return RewardedAdResult.unsupported;

    try {
      await initialize();

      RewardedAd? ad = _rewardedAd;
      _rewardedAd = null;

      ad ??= await _loadRewardedOnDemand();
      if (ad == null) {
        return RewardedAdResult.unavailable;
      }

      var rewardEarned = false;
      Future<void>? rewardFuture;
      final doneCompleter = Completer<RewardedAdResult>();

      ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
        onAdDismissedFullScreenContent: (dismissedAd) async {
          dismissedAd.dispose();
          if (rewardFuture != null) {
            await rewardFuture;
          }
          if (!doneCompleter.isCompleted) {
            doneCompleter.complete(
              rewardEarned
                  ? RewardedAdResult.rewarded
                  : RewardedAdResult.dismissedWithoutReward,
            );
          }
          unawaited(preloadRewardedAd());
        },
        onAdFailedToShowFullScreenContent: (failedAd, error) {
          debugPrint(
            'AdMob rewarded failed to show (code ${error.code}): ${error.message}',
          );
          failedAd.dispose();
          if (!doneCompleter.isCompleted) {
            doneCompleter.complete(RewardedAdResult.unavailable);
          }
          unawaited(preloadRewardedAd());
        },
      );

      await ad.show(
        onUserEarnedReward: (AdWithoutView _, RewardItem reward) {
          rewardEarned = true;
          rewardFuture = onEarnedReward(reward);
        },
      );

      return await doneCompleter.future;
    } catch (e) {
      debugPrint('AdMob rewarded show failed: $e');
      return RewardedAdResult.unavailable;
    }
  }

  static Future<RewardedAd?> _loadRewardedOnDemand() async {
    final completer = Completer<RewardedAd?>();
    try {
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (!completer.isCompleted) completer.complete(ad);
          },
          onAdFailedToLoad: (error) {
            debugPrint(
              'AdMob rewarded on-demand load failed (code ${error.code}): ${error.message}',
            );
            if (!completer.isCompleted) completer.complete(null);
          },
        ),
      );
      return await completer.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () => null,
      );
    } catch (e) {
      debugPrint('AdMob rewarded on-demand exception: $e');
      return null;
    }
  }
}
