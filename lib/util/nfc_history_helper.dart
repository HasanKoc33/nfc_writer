import 'dart:convert';
import '../data/model/nfc_history_item.dart';
import '../data/repositories/nfc_history_repository.dart';
import '../core/utils/analytics_helper.dart';

class NfcHistoryHelper {
  static final NfcHistoryRepository _repository = NfcHistoryRepository();

  static Future<void> saveReadHistory({
    required String title,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final item = NfcHistoryItem(
      title: title,
      type: type,
      content: jsonEncode(data),
      category: NfcHistoryCategory.read,
      metadata: {'source': 'nfc_read'},
    );

    await _repository.saveReadHistory(item);
    await AnalyticsHelper.trackCustomEvent(
      eventName: 'history_item_saved',
      parameters: {'type': type, 'category': 'read'},
    );
  }

  static Future<void> saveWriteHistory({
    required String title,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final item = NfcHistoryItem(
      title: title,
      type: type,
      content: jsonEncode(data),
      category: NfcHistoryCategory.write,
      metadata: {'source': 'nfc_write'},
    );

    await _repository.saveWriteHistory(item);
    await AnalyticsHelper.trackCustomEvent(
      eventName: 'history_item_saved',
      parameters: {'type': type, 'category': 'write'},
    );
  }

  static String extractTitle(String type, String content,
      {int maxLength = 30}) {
    try {
      if (content.length <= maxLength) {
        return content;
      }
      return '${content.substring(0, maxLength)}...';
    } catch (e) {
      return type.toUpperCase();
    }
  }

  static Future<void> saveUrlRead(String url) async {
    await saveReadHistory(
      title: extractTitle('URL', url),
      type: NfcHistoryType.url,
      data: {'url': url},
    );
  }

  static Future<void> saveTextRead(String text) async {
    await saveReadHistory(
      title: extractTitle('Text', text),
      type: NfcHistoryType.text,
      data: {'text': text},
    );
  }

  static Future<void> saveWifiRead(Map<String, String> wifiData) async {
    final ssid = wifiData['S'] ?? 'Unknown';
    await saveReadHistory(
      title: 'WiFi: $ssid',
      type: NfcHistoryType.wifi,
      data: wifiData,
    );
  }

  static Future<void> savePhoneRead(String phone) async {
    await saveReadHistory(
      title: 'Phone: $phone',
      type: NfcHistoryType.phone,
      data: {'phone': phone},
    );
  }

  static Future<void> saveEmailRead(String email) async {
    await saveReadHistory(
      title: 'Email: $email',
      type: NfcHistoryType.email,
      data: {'email': email},
    );
  }

  static Future<void> saveLocationRead(String location) async {
    await saveReadHistory(
      title: 'Location',
      type: NfcHistoryType.location,
      data: {'location': location},
    );
  }

  static Future<void> saveSmsRead(String sms) async {
    await saveReadHistory(
      title: 'SMS',
      type: NfcHistoryType.sms,
      data: {'sms': sms},
    );
  }

  static Future<void> saveVcardRead(String vcard) async {
    await saveReadHistory(
      title: 'Contact',
      type: NfcHistoryType.vcard,
      data: {'vcard': vcard},
    );
  }

  static Future<void> saveOtherRead(String content, String mimeType) async {
    await saveReadHistory(
      title: extractTitle('Other', content),
      type: NfcHistoryType.other,
      data: {'content': content, 'mimeType': mimeType},
    );
  }
}
