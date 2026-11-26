import 'dart:io';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:nfc_writer/data/services/app_ads_service.dart';
import 'package:nfc_writer/data/services/nfc_service/nfc_service.dart';
import 'package:nfc_writer/util/ndef_record_codec.dart';

import 'reading_screen.dart';

/// ReadingScreen mixin sınıfı
mixin ReadingScreenMixin on State<ReadingScreen> {
  ValueNotifier<Ndef?> result = ValueNotifier(null);
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.android) {
      tagRead();
    }
    AppAdsService.instance.loadHomeBannerAd();
    AppAdsService.instance.loadInterstitialAd();
  }

  @override
  void dispose() {
    super.dispose();
    NfcService.instance.stopSession();
  }

  void tagRead() => NfcManager.instance.startSession(
        alertMessageIos: 'nfc.scan.ios_alert'.tr(),
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          result.value = Ndef.from(tag);
          final records = result.value?.cachedMessage?.records;
          if (records != null) {
            NdefRecordCodec.saveToHistory(records, isWrite: false);
          }
          if (defaultTargetPlatform == TargetPlatform.iOS) {
            NfcService.instance.stopSession(
              alertMessageIos: 'nfc.scan.ios_read_success'.tr(),
              errorMessageIos: 'nfc.scan.ios_read_error'.tr(),
            );
          }
        },
      );

  List<PieChartSectionData> showingSections() {
    int max = result.value?.maxSize ?? 0;
    int size = result.value?.cachedMessage?.byteLength ?? 0;
    int free = max - size;

    return List.generate(2, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;

      switch (i) {
        case 1:
          return PieChartSectionData(
            color: Colors.grey,
            value: size.toDouble(),
            title: '$size byte',
            radius: radius,
            titleStyle: TextStyle(fontSize: fontSize, color: Colors.black),
          );
        case 0:
          return PieChartSectionData(
            color: Colors.green,
            value: free.toDouble(),
            title: '$free byte',
            radius: radius,
            titleStyle: TextStyle(fontSize: fontSize, color: Colors.black),
          );
        default:
          throw Error();
      }
    });
  }
}
