import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// ignore: depend_on_referenced_packages
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// ignore: depend_on_referenced_packages, implementation_imports
import 'package:in_app_purchase_android/src/billing_client_wrappers/billing_client_wrapper.dart';

/// ignore: depend_on_referenced_packages
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app/app.dart';
import '../../../core/constants/app_constants.dart';
import '../../../util/debug.dart';
import '../app_ads_service.dart';
import 'iap_callback.dart';
import 'iap_receipt_data.dart';

class InAppPurchaseHelper {
  static final InAppPurchaseHelper _inAppPurchaseHelper =
      InAppPurchaseHelper._internal();

  InAppPurchaseHelper._internal();

  factory InAppPurchaseHelper() {
    return _inAppPurchaseHelper;
  }

  static String getProductId() {
    if (Platform.isAndroid) {
      return AppConstants.productIdAndroid.value;
    } else {
      return AppConstants.productIdiOS.value;
    }
  }

  static String getProProductId() {
    if (Platform.isAndroid) {
      return AppConstants.productIdProAndroid.value;
    } else {
      return AppConstants.productIdProiOS.value;
    }
  }

  static List<String> get _kProductIds => <String>[
    getProductId(),
    getProProductId(),
  ];

  final InAppPurchase _connection = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  IAPCallback? _iapCallback;

  /// Geçmiş satın alımları geri yükler. iOS'ta Apple hesabı girişi
  /// isteyebileceği için yalnızca kullanıcı "Satın Alımı Geri Yükle"ye
  /// bastığında çağrılmalı. Sonuçlar [purchaseStream] üzerinden gelir.
  /// Kullanıcı girişi iptal ederse StoreKit SKError fırlatır; bu hata
  /// yakalanıp callback'e iletilir.
  Future<void> restorePurchases() async {
    try {
      await _connection.restorePurchases();
    } catch (error) {
      Debug.printLog('Restore', error.toString());
      handleError(error);
    }
  }

  ProductDetails? getProductDetail(String productID) {
    for (ProductDetails item in _products) {
      if (item.id == productID) {
        return item;
      }
    }
    return null;
  }

  String? getProductPrice(String productId) {
    for (final product in _products) {
      if (product.id == productId) return product.price;
    }
    return null;
  }

  getAlreadyPurchaseItems(IAPCallback iapCallback) {
    _iapCallback = iapCallback;
    // purchaseStream tek sefer dinlenir; her ekran yeniden abone olursa
    // aynı satın alma birden çok kez işlenir.
    if (_subscription != null) {
      initStoreInfo();
      return;
    }
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _connection.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        if (purchaseDetailsList.isNotEmpty) {
          purchaseDetailsList.sort(
            (a, b) => a.transactionDate!.compareTo(b.transactionDate!),
          );

          if (purchaseDetailsList[0].status == PurchaseStatus.restored) {
            getPastPurchases(purchaseDetailsList);
          } else {
            _listenToPurchaseUpdated(purchaseDetailsList);
          }
        }
      },
      onDone: () {
        _subscription?.cancel();
        _subscription = null;
      },
      onError: (error) {
        handleError(error);
      },
    );
    initStoreInfo();
  }

  Future<void> initStoreInfo() async {
    final bool isAvailable = await _connection.isAvailable();
    if (!isAvailable) {
      _products = [];
      _purchases = [];
      _iapCallback?.onLoaded(false);
      return;
    }

    ProductDetailsResponse productDetailResponse = await _connection
        .queryProductDetails(_kProductIds.toSet());

    _products = productDetailResponse.productDetails;
    _purchases = [];
    Debug.printLog('Products', _products.toString());

    // Android'de geri yükleme sessizdir ve satın alımların onaylanması için
    // gerekir. iOS'ta ise Apple hesabı girişi açtığından otomatik yapılmaz;
    // kullanıcı geri yükleme butonuyla başlatır.
    if (Platform.isAndroid) {
      await restorePurchases();
    }
    _iapCallback?.onLoaded(true);
  }

  Future<void> getPastPurchases(List<PurchaseDetails> verifiedPurchases) async {
    verifiedPurchases.sort(
      (a, b) => a.transactionDate!.compareTo(b.transactionDate!),
    );

    if (Platform.isIOS) {
      if (verifiedPurchases.isNotEmpty) {
        await _verifyProductReceipts(verifiedPurchases);
      } else {
        Debug.printLog('', 'You have not Purchased');
        await setSubscription(false);
        _iapCallback?.onBillingError(
          "You haven't purchase our product, so we can't restore.",
        );
      }
      return;
    }

    if (verifiedPurchases.isNotEmpty) {
      _purchases = verifiedPurchases;
      Debug.printLog('', 'You have already Purchased');
      await setSubscription(true);
      for (var element in _purchases) {
        App.purchaseStreamController.add(element);
        _iapCallback?.onSuccessPurchase(element);
      }
    } else {
      Debug.printLog('', 'You have not Purchased');
      await setSubscription(false);
      _iapCallback?.onBillingError(
        "You haven't purchase our product, so we can't restore.",
      );
    }
  }

  _verifyProductReceipts(List<PurchaseDetails> verifiedPurchases) async {
    var dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(milliseconds: 5000),
        receiveTimeout: const Duration(milliseconds: 5000),
      ),
    );

    Map<String, String> data = {};
    data.putIfAbsent(
      'receipt-data',
      () => verifiedPurchases[0].verificationData.localVerificationData,
    );

    try {
      String verifyReceiptUrl;
      if (Debug.sandboxVerifyReceiptUrl) {
        verifyReceiptUrl = 'https://sandbox.itunes.apple.com/verifyReceipt';
      } else {
        verifyReceiptUrl = 'https://buy.itunes.apple.com/verifyReceipt';
      }

      final graphResponse = await dio.post<String>(
        verifyReceiptUrl,
        data: data,
      );
      Map<String, dynamic> profile = jsonDecode(graphResponse.data!);
      var receiptData = IapReceiptData.fromJson(profile);

      if (receiptData.latestReceiptInfo != null) {
        receiptData.latestReceiptInfo!.sort(
          (a, b) => b.expiresDateMs!.compareTo(a.expiresDateMs!),
        );
        if (int.parse(receiptData.latestReceiptInfo![0].expiresDateMs!) >
            DateTime.now().millisecondsSinceEpoch) {
          for (PurchaseDetails purchaseData in verifiedPurchases) {
            if (purchaseData.productID ==
                receiptData.latestReceiptInfo![0].productId) {
              _purchases.clear();
              _purchases.add(purchaseData);
              if (_purchases.isNotEmpty) {
                await setSubscription(true);
                for (var element in _purchases) {
                  App.purchaseStreamController.add(element);
                  _iapCallback?.onSuccessPurchase(element);
                }
              } else {
                await setSubscription(false);
                _iapCallback?.onBillingError('');
              }
              Debug.printLog(
                '',
                'Already Purchased => ${receiptData.latestReceiptInfo![0].toJson()}',
              );
              return;
            } else {
              await setSubscription(false);
              _iapCallback?.onBillingError('');
            }

            if (purchaseData.pendingCompletePurchase) {
              await _connection.completePurchase(purchaseData);
            }
          }
        } else {
          await setSubscription(false);
          _iapCallback?.onBillingError('');
        }
      }
    } on DioException catch (ex) {
      try {
        await setSubscription(false);
        _iapCallback?.onBillingError('');
        Debug.printLog('', 'Verify Receipt => ${ex.response!.data}');
      } catch (e) {
        await setSubscription(false);
        _iapCallback?.onBillingError('');
        Debug.printLog('', e.toString());
      }
    }
  }

  Map<String, PurchaseDetails> getPurchases() {
    Map<String, PurchaseDetails> purchases = Map.fromEntries(
      _purchases.map((PurchaseDetails purchase) {
        if (purchase.pendingCompletePurchase) {
          _connection.completePurchase(purchase);
        }
        return MapEntry<String, PurchaseDetails>(purchase.productID, purchase);
      }),
    );
    return purchases;
  }

  Future<void> finishTransaction() async {
    if (!Platform.isIOS) return;
    final transactions = await SKPaymentQueueWrapper().transactions();
    for (final transaction in transactions) {
      try {
        if (transaction.transactionState !=
            SKPaymentTransactionStateWrapper.purchasing) {
          await SKPaymentQueueWrapper().finishTransaction(transaction);
          if (transaction.originalTransaction != null) {
            await SKPaymentQueueWrapper().finishTransaction(
              transaction.originalTransaction!,
            );
          }
        }
      } catch (e) {
        Debug.printLog('', e.toString());
        _iapCallback?.onBillingError(e);
      }
    }
  }

  Future<void> clearTransactions() async {
    if (!Platform.isIOS) return;
    final transactions = await SKPaymentQueueWrapper().transactions();
    for (final transaction in transactions) {
      try {
        if (transaction.transactionState !=
            SKPaymentTransactionStateWrapper.purchasing) {
          await SKPaymentQueueWrapper().finishTransaction(transaction);
          if (transaction.originalTransaction != null) {
            await SKPaymentQueueWrapper().finishTransaction(
              transaction.originalTransaction!,
            );
          }
        }
      } catch (e) {
        _iapCallback?.onBillingError(e);
        Debug.printLog('', e.toString());
      }
    }
  }

  Future<void> buyNonConsumable(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
      applicationUserName: null,
    );
    try {
      await _connection.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (error) {
      handleError(error);
      Debug.printLog('', error.toString());
    }
  }

  Future<void> buySubscription(
    ProductDetails productDetails,
    Map<String, PurchaseDetails> purchases,
  ) async {
    if (Platform.isIOS) {
      await clearTransactions();
    }

    PurchaseParam purchaseParam;

    if (Platform.isAndroid) {
      final oldSubscription = _getOldSubscription(productDetails, purchases);
      purchaseParam = GooglePlayPurchaseParam(
        productDetails: productDetails,
        applicationUserName: null,
        changeSubscriptionParam: (oldSubscription != null)
            ? ChangeSubscriptionParam(
                oldPurchaseDetails: oldSubscription,
                replacementMode: ReplacementMode.withTimeProration,
              )
            : null,
      );
    } else {
      purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: null,
      );
    }

    _connection.buyNonConsumable(purchaseParam: purchaseParam).catchError((
      error,
    ) async {
      handleError(error);
      Debug.printLog('', error.toString());
      return true;
    });
  }

  void deliverProduct(PurchaseDetails purchaseDetails) async {
    _purchases.add(purchaseDetails);
    App.purchaseStreamController.add(purchaseDetails);
    _iapCallback?.onSuccessPurchase(purchaseDetails);
  }

  void handleError(dynamic error) {
    _iapCallback?.onBillingError(error);
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) {
    return Future<bool>.value(true);
  }

  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {}

  Future<void> _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final detailsPurchase in purchaseDetailsList) {
      if (detailsPurchase.status == PurchaseStatus.pending) {
        _iapCallback?.onPending(detailsPurchase);
      } else {
        if (detailsPurchase.status == PurchaseStatus.error) {
          handleError(detailsPurchase.error);
        } else if (detailsPurchase.status == PurchaseStatus.restored) {
          getPastPurchases(purchaseDetailsList);
        } else if (detailsPurchase.status == PurchaseStatus.canceled) {
          _iapCallback?.onBillingError(detailsPurchase.error);
        } else if (detailsPurchase.status == PurchaseStatus.purchased) {
          bool valid = await _verifyPurchase(detailsPurchase);
          if (valid) {
            deliverProduct(detailsPurchase);
          } else {
            _handleInvalidPurchase(detailsPurchase);
            continue;
          }
        }

        if (detailsPurchase.pendingCompletePurchase) {
          await _connection.completePurchase(detailsPurchase);
          await finishTransaction();
        }
      }
    }
    await clearTransactions();
  }

  GooglePlayPurchaseDetails? _getOldSubscription(
    ProductDetails productDetails,
    Map<String, PurchaseDetails> purchases,
  ) {
    return purchases[productDetails.id] as GooglePlayPurchaseDetails?;
  }

  Future<void> setSubscription(bool value) async {
    final pref = await SharedPreferences.getInstance();
    if (value) {
      FacebookAppEvents().logPurchase(amount: 1.5, currency: 'USD');
      AppAdsService.instance.removeAds();
    }
    await pref.setBool(AppConstants.premiumKey.value, value);
  }

  Future<bool> getSubscription() async {
    // Debug build'lerde premium özellikler açık (release'i etkilemez).
    if (kDebugMode) return true;
    final pref = await SharedPreferences.getInstance();
    return pref.getBool(AppConstants.premiumKey.value) ?? false;
  }
}
