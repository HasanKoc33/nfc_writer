import 'dart:async';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_writer/data/services/app_ads_service.dart';

import '../../../core/app/app.dart';
import '../../../core/services/review_service.dart';
import '../../../data/model/nfc_history_item.dart';
import '../../../data/services/in_app_purchase/iap_callback.dart';
import '../../../data/services/in_app_purchase/in_app_purchase_helper.dart';
import '../../../data/services/dynamic_link/dynamic_link_models.dart';
import '../../../data/services/nfc_service/nfc_service.dart';
import '../../../util/ndef_record_codec.dart';
import '../dynamic_links/dynamic_links_screen.dart';
import '../history_screen/history_screen.dart';
import '../pro_versiyon/pro_versiyon.dart';
import '../reading_screen/reading_screen.dart';
import '../settings/settings_screen.dart';
import '../writing_screen/writing_screen.dart';

/// HomeScreen ekranı
class HomeScreen extends StatefulWidget {
  /// HomeScreen ekranı
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> implements IAPCallback {
  int currentIndex = 0;
  int _tabSwitchCount = 0;
  bool _isPremium = true;
  StreamSubscription<PurchaseDetails>? _purchaseSubscription;

  @override
  void initState() {
    super.initState();
    AppAdsService.instance.loadInterstitialAd();
    _listenPurchaseStream();
    InAppPurchaseHelper().getAlreadyPurchaseItems(this);
    _refreshPremium();
    // Her açılışta değerlendirme istenir; ekran oturduktan sonra gösterilir.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) ReviewService.instance.request();
    });
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshPremium() async {
    final isPremium = await InAppPurchaseHelper().getSubscription();
    if (mounted) setState(() => _isPremium = isPremium);
  }

  void _listenPurchaseStream() {
    _purchaseSubscription = App.purchaseStreamController.stream.listen((
      product,
    ) {
      try {
        if (product.productID == InAppPurchaseHelper.getProductId() ||
            product.productID == InAppPurchaseHelper.getProProductId()) {
          InAppPurchaseHelper().setSubscription(true);
          if (mounted) setState(() => _isPremium = true);
        }
      } on Exception {
        InAppPurchaseHelper().setSubscription(false);
      }
    });
  }

  void _selectTab(int index) {
    if (index == currentIndex) return;
    _tabSwitchCount++;
    // Her 5 sekme değişiminde bir geçiş reklamı gösterilir.
    if (_tabSwitchCount % 5 == 0) {
      AppAdsService.instance.interstitialAd?.show();
    }
    setState(() => currentIndex = index);
  }

  /// Geçmişten seçilen kaydı yazma taslağına ekleyip Yaz sekmesine geçer.
  void _useHistoryItem(NfcHistoryItem item) {
    final record = NdefRecordCodec.fromHistory(
      item,
      languageCode: context.locale.languageCode,
    );
    if (record == null) return;
    WriteDraft.add(record);
    _selectTab(1);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('ui.history.added_to_write'.tr())));
  }

  /// Okunan etiketin kayıtlarını birebir kopyalayıp yazma taslağına koyar.
  /// Taslakta önceden kayıt varsa "Geri al" ile eski hâline dönülebilir.
  void _copyTagToWrite(List<NdefRecord> records) {
    final previous = WriteDraft.message.value;
    WriteDraft.message.value = NdefMessage(
      records: [
        for (final r in records)
          NdefRecord(
            typeNameFormat: r.typeNameFormat,
            type: Uint8List.fromList(r.type),
            identifier: Uint8List.fromList(r.identifier),
            payload: Uint8List.fromList(r.payload),
          ),
      ],
    );
    _selectTab(1);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'ui.scan.copied_to_write'.tr(
            namedArgs: {'count': '${records.length}'},
          ),
        ),
        action: previous.records.isEmpty
            ? null
            : SnackBarAction(
                label: 'ui.scan.undo'.tr(),
                onPressed: () => WriteDraft.message.value = previous,
              ),
      ),
    );
  }

  void _addDynamicLinkToWrite(DynamicLink link) {
    WriteDraft.add(NfcService.instance.createUriRecord(uri: link.shortUrl));
    _selectTab(1);
  }

  Future<void> _openPro() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProVersiyonScreen()),
    );
    _refreshPremium();
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    _refreshPremium();
  }

  String get _title {
    switch (currentIndex) {
      case 1:
        return 'home.tabs.write'.tr();
      case 2:
        return 'ui.dynamic.tab'.tr();
      case 3:
        return 'ui.tabs.history'.tr();
      default:
        return 'home.tabs.scan'.tr();
    }
  }

  Widget get _body {
    switch (currentIndex) {
      case 1:
        return const WritingScreen();
      case 2:
        return DynamicLinksScreen(onAddToWrite: _addDynamicLinkToWrite);
      case 3:
        return HistoryScreen(embedded: true, onUseItem: _useHistoryItem);
      default:
        return ReadingScreen(onCopyToWrite: _copyTagToWrite);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          if (!_isPremium)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: ActionChip(
                avatar: Icon(
                  Icons.workspace_premium_rounded,
                  size: 18,
                  color: scheme.tertiary,
                ),
                label: const Text('PRO'),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: scheme.tertiary,
                ),
                side: BorderSide(color: scheme.tertiary.withValues(alpha: 0.4)),
                backgroundColor: scheme.tertiary.withValues(alpha: 0.08),
                onPressed: _openPro,
              ),
            ),
          IconButton(
            tooltip: 'ui.settings.title'.tr(),
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(key: ValueKey(currentIndex), child: _body),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _selectTab,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.nfc_outlined),
            selectedIcon: const Icon(Icons.nfc_rounded),
            label: 'home.tabs.scan'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.edit_outlined),
            selectedIcon: const Icon(Icons.edit_rounded),
            label: 'home.tabs.write'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.alt_route_outlined),
            selectedIcon: const Icon(Icons.alt_route_rounded),
            label: 'ui.dynamic.tab'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history_rounded),
            label: 'ui.tabs.history'.tr(),
          ),
        ],
      ),
    );
  }

  @override
  void onBillingError(error) {}

  @override
  void onLoaded(bool initialized) {}

  @override
  void onPending(PurchaseDetails product) {}

  @override
  void onSuccessPurchase(PurchaseDetails product) {
    if (mounted) setState(() => _isPremium = true);
  }
}
