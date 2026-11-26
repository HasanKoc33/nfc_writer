import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'in_app_purchase/in_app_purchase_helper.dart';

class AppAdsService {
  AppAdsService._();

  static AppAdsService? _instance;

  static AppAdsService get instance => _instance ??= AppAdsService._();

  final String _androidBannerId = 'ca-app-pub-9536972853663383/8528513583';
  final String _androidInterstitialId =
      'ca-app-pub-9536972853663383/3015624611';
  final String _iosBannerId = 'ca-app-pub-6139386909716103/4720766294';
  final String _iosInterstitialId = 'ca-app-pub-6139386909716103/4927311128';

  String get _homebannerAdId => defaultTargetPlatform == TargetPlatform.iOS
      ? _iosBannerId
      : _androidBannerId;

  String get _interstitialAdId => defaultTargetPlatform == TargetPlatform.iOS
      ? _iosInterstitialId
      : _androidInterstitialId;

  BannerAd? _homebannerAd;
  InterstitialAd? _interstitialAd;

  BannerAd? get homebannerAd => _homebannerAd;
  InterstitialAd? get interstitialAd => _interstitialAd;

  final StreamController<bool> _bannerIsLoaded =
      StreamController<bool>.broadcast();
  Stream<bool> get bannerIsLoaded => _bannerIsLoaded.stream;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  Future<void> loadHomeBannerAd() async {
    final removeAds = await InAppPurchaseHelper().getSubscription();
    if (removeAds) return;

    _homebannerAd = BannerAd(
      adUnitId: _homebannerAdId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          _bannerIsLoaded.add(true);
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          debugPrint('BannerAd failed to load: $error');
        },
      ),
    )..load();
  }

  Future<void> loadInterstitialAd() async {
    final removeAds = await InAppPurchaseHelper().getSubscription();
    if (removeAds) return;

    InterstitialAd.load(
      adUnitId: _interstitialAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  void removeAds() {
    _interstitialAd = null;
    _homebannerAd = null;
  }
}
