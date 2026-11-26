import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/services/ad_service.dart';
import '../providers/app_providers.dart';

/// Anchored adaptive AdMob Banner widget.
///
/// - Automatically hides and disposes itself whenever the user's 24h Rewarded
///   Ad-Free Pass is active.
/// - Gracefully collapses to zero height when offline, unsupported platform, or
///   before the ad finishes loading so the app layout never jumps or errors.
class AdBannerWidget extends ConsumerStatefulWidget {
  const AdBannerWidget({super.key});

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  int? _lastLoadedWidth;
  Timer? _expiryTimer;

  bool _isPassActive(DateTime? adFreeUntil) {
    return adFreeUntil != null && adFreeUntil.isAfter(DateTime.now());
  }

  void _scheduleExpiryTimer(DateTime? adFreeUntil) {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    if (adFreeUntil == null) return;
    final remaining = adFreeUntil.difference(DateTime.now());
    if (remaining <= Duration.zero) return;
    _expiryTimer = Timer(remaining + const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _lastLoadedWidth = null;
      });
      final width = MediaQuery.sizeOf(context).width.truncate();
      if (width > 0) {
        _lastLoadedWidth = width;
        _loadAdaptiveBanner(width);
      }
    });
  }

  void _clearBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
    _lastLoadedWidth = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!AdService.isSupported) return;
    final adFreeUntil = ref.read(adFreePassProvider);
    if (_isPassActive(adFreeUntil)) {
      _scheduleExpiryTimer(adFreeUntil);
      return;
    }
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width > 0 && width != _lastLoadedWidth) {
      _lastLoadedWidth = width;
      _loadAdaptiveBanner(width);
    }
  }

  Future<void> _loadAdaptiveBanner(int width) async {
    try {
      await AdService.initialize();
      if (!mounted) return;
      if (_isPassActive(ref.read(adFreePassProvider))) return;

      final adaptiveSize =
          await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (!mounted) return;
      if (_isPassActive(ref.read(adFreePassProvider))) return;

      final size = adaptiveSize ?? AdSize.banner;

      _bannerAd?.dispose();
      _bannerAd = null;
      if (_isLoaded) {
        setState(() => _isLoaded = false);
      }

      final banner = BannerAd(
        adUnitId: AdService.bannerAdUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted || _isPassActive(ref.read(adFreePassProvider))) {
              ad.dispose();
              return;
            }
            setState(() {
              _bannerAd = ad as BannerAd;
              _isLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            debugPrint(
              'AdMob banner failed to load (code ${error.code}): ${error.message}',
            );
            if (mounted && _isLoaded) {
              setState(() {
                _bannerAd = null;
                _isLoaded = false;
              });
            }
          },
        ),
      );

      await banner.load();
    } catch (e) {
      debugPrint('AdMob banner setup skipped/failed: $e');
    }
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adFreeUntil = ref.watch(adFreePassProvider);
    final isAdFree = _isPassActive(adFreeUntil);

    if (isAdFree) {
      if (_bannerAd != null || _isLoaded) {
        _clearBanner();
      }
      _scheduleExpiryTimer(adFreeUntil);
      return const SizedBox.shrink();
    }

    if (AdService.isSupported && _bannerAd == null && _lastLoadedWidth == null) {
      final width = MediaQuery.sizeOf(context).width.truncate();
      if (width > 0) {
        _lastLoadedWidth = width;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isPassActive(ref.read(adFreePassProvider))) {
            _loadAdaptiveBanner(width);
          }
        });
      }
    }

    final ad = _bannerAd;
    if (!AdService.isSupported || !_isLoaded || ad == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      alignment: Alignment.center,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
