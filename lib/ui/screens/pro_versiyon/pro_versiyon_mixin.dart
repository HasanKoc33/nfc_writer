import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:nfc_writer/core/constants/app_constants.dart';
import 'package:nfc_writer/ui/screens/pro_versiyon/pro_versiyon.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../data/services/in_app_purchase/iap_callback.dart';
import '../../../data/services/in_app_purchase/in_app_purchase_helper.dart';

/// ProVersiyonScreen mixin sınıfı
mixin ProVersiyonScreenMixin on State<ProVersiyonScreen>
    implements IAPCallback {
  Map<String, PurchaseDetails>? purchases;
  bool isShowProgress = false;

  @override
  void initState() {
    InAppPurchaseHelper().getAlreadyPurchaseItems(this);
    purchases = InAppPurchaseHelper().getPurchases();
    InAppPurchaseHelper().clearTransactions();
    super.initState();
  }

  onClickPrivacyPolicy() {
    launchUrlString(AppConstants.privacyPolicy.value);
  }

  onClickTermsAndCondition() {
    launchUrlString(AppConstants.termsAndCondition.value);
  }

  onClickRestore() {
    setState(() {
      isShowProgress = true;
    });
    InAppPurchaseHelper().getAlreadyPurchaseItems(this);
    InAppPurchaseHelper().restorePurchases();
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted) setState(() { isShowProgress = false; });
    });
  }

  onPurchaseClick(String productType) async {
    setState(() {
      isShowProgress = true;
    });

    final productId = productType == 'pro_version'
        ? InAppPurchaseHelper.getProProductId()
        : InAppPurchaseHelper.getProductId();

    ProductDetails? product = InAppPurchaseHelper().getProductDetail(productId);
    if (product != null) {
      await InAppPurchaseHelper().buyNonConsumable(product);
    } else {
      if (mounted) setState(() { isShowProgress = false; });
    }
  }

  @override
  void onBillingError(error) {
    if (mounted) setState(() { isShowProgress = false; });
  }

  @override
  void onLoaded(bool initialized) {
    if (mounted) setState(() {});
  }

  @override
  void onPending(PurchaseDetails product) {}

  @override
  void onSuccessPurchase(PurchaseDetails product) {
    InAppPurchaseHelper().setSubscription(true);
    if (mounted) {
      setState(() { isShowProgress = false; });
      Navigator.pop(context);
    }
  }
}
