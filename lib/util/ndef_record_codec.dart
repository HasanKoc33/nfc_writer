import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/ndef_record.dart';

import '../data/model/nfc_history_item.dart';
import '../data/services/nfc_service/nfc_service.dart';
import 'nfc_history_helper.dart';

/// Geçmişe kaydedilecek bir NDEF kaydının özeti.
class NdefRecordSummary {
  const NdefRecordSummary({
    required this.type,
    required this.title,
    required this.data,
  });

  final String type;
  final String title;
  final Map<String, dynamic> data;
}

/// Yazma ekranındaki taslak. Sekme değişince WritingScreen yeniden
/// oluşturulsa da eklenen kayıtlar kaybolmasın diye ekrandan bağımsız tutulur.
class WriteDraft {
  WriteDraft._();

  static final ValueNotifier<NdefMessage> message = ValueNotifier(
    NdefMessage(records: []),
  );

  static void add(NdefRecord record) {
    message.value = NdefMessage(records: [...message.value.records, record]);
  }
}

/// NDEF kayıtlarını geçmiş kayıtlarına ve geri dönüştürür.
class NdefRecordCodec {
  NdefRecordCodec._();

  /// NFC Forum URI tanımlayıcı kodları (payload'ın ilk baytı).
  static const List<String> _uriPrefixes = [
    '',
    'http://www.',
    'https://www.',
    'http://',
    'https://',
    'tel:',
    'mailto:',
    'ftp://anonymous:anonymous@',
    'ftp://ftp.',
    'ftps://',
    'sftp://',
    'smb://',
    'nfs://',
    'ftp://',
    'dav://',
    'news:',
    'telnet://',
    'imap:',
    'rtsp://',
    'urn:',
    'pop:',
    'sip:',
    'sips:',
    'tftp:',
    'btspp://',
    'btl2cap://',
    'btgoep://',
    'tcpobex://',
    'irdaobex://',
    'file://',
    'urn:epc:id:',
    'urn:epc:tag:',
    'urn:epc:pat:',
    'urn:epc:raw:',
    'urn:epc:',
    'urn:nfc:',
  ];

  static String decodeUri(Uint8List payload) {
    if (payload.isEmpty) return '';
    final code = payload[0];
    final prefix = code < _uriPrefixes.length ? _uriPrefixes[code] : '';
    return prefix + utf8.decode(payload.sublist(1), allowMalformed: true);
  }

  static String decodeText(Uint8List payload) {
    if (payload.isEmpty) return '';
    final languageCodeLength = payload[0] & 0x3f;
    if (payload.length <= languageCodeLength) return '';
    return utf8.decode(
      payload.sublist(1 + languageCodeLength),
      allowMalformed: true,
    );
  }

  static Map<String, String> parseWifi(String text) {
    final result = <String, String>{};
    final body = text.startsWith('WIFI:') ? text.substring(5) : text;
    for (final part in body.split(';')) {
      final index = part.indexOf(':');
      if (index <= 0) continue;
      result[part.substring(0, index)] = part.substring(index + 1);
    }
    return result;
  }

  static NdefRecordSummary summarize(NdefRecord record) {
    final type = String.fromCharCodes(record.type);
    if (record.typeNameFormat == TypeNameFormat.wellKnown) {
      if (type == 'U' || type.isEmpty) {
        final uri = decodeUri(record.payload);
        if (uri.startsWith('tel:')) {
          final phone = uri.substring(4);
          return NdefRecordSummary(
            type: NfcHistoryType.phone,
            title: phone,
            data: {'phone': phone},
          );
        }
        if (uri.startsWith('mailto:')) {
          final email = uri.substring(7);
          return NdefRecordSummary(
            type: NfcHistoryType.email,
            title: email.split('?').first,
            data: {'email': email},
          );
        }
        if (uri.startsWith('geo:')) {
          return NdefRecordSummary(
            type: NfcHistoryType.location,
            title: uri.substring(4),
            data: {'location': uri},
          );
        }
        if (uri.startsWith('sms:')) {
          return NdefRecordSummary(
            type: NfcHistoryType.sms,
            title: uri.substring(4).split('?').first,
            data: {'sms': uri},
          );
        }
        return NdefRecordSummary(
          type: NfcHistoryType.url,
          title: NfcHistoryHelper.extractTitle('URL', uri, maxLength: 60),
          data: {'url': uri},
        );
      }
      if (type == 'T') {
        final text = decodeText(record.payload);
        return NdefRecordSummary(
          type: NfcHistoryType.text,
          title: NfcHistoryHelper.extractTitle('Text', text, maxLength: 60),
          data: {'text': text},
        );
      }
    }
    if (record.typeNameFormat == TypeNameFormat.media) {
      final content = utf8.decode(record.payload, allowMalformed: true);
      if (type == 'application/vnd.wfa.wsc' && content.startsWith('WIFI:')) {
        final wifi = parseWifi(content);
        return NdefRecordSummary(
          type: NfcHistoryType.wifi,
          title: wifi['S'] ?? 'Wi‑Fi',
          data: wifi,
        );
      }
      if (type.contains('vcard')) {
        return NdefRecordSummary(
          type: NfcHistoryType.vcard,
          title: 'vCard',
          data: {'vcard': content},
        );
      }
      return NdefRecordSummary(
        type: NfcHistoryType.other,
        title: NfcHistoryHelper.extractTitle(type, content, maxLength: 60),
        data: {'content': content, 'mimeType': type},
      );
    }
    final content = utf8.decode(record.payload, allowMalformed: true);
    return NdefRecordSummary(
      type: NfcHistoryType.other,
      title: NfcHistoryHelper.extractTitle(type, content, maxLength: 60),
      data: {'content': content, 'mimeType': type},
    );
  }

  /// NFC etiketine sığması için en kısa geçerli vCard 3.0 metnini üretir:
  /// yalnızca dolu alanlar yazılır, satırlar CRLF ile ayrılır.
  static String buildVCard({
    required String name,
    String phone = '',
    String email = '',
    String company = '',
    String website = '',
  }) {
    String esc(String v) => v
        .trim()
        .replaceAll('\\', '\\\\')
        .replaceAll(',', r'\,')
        .replaceAll(';', r'\;')
        .replaceAll(RegExp(r'[\r\n]+'), ' ');

    final fullName = name.trim();
    // N alanı vCard 3.0'da zorunlu: "Soyad;Ad". Son kelime soyad sayılır.
    final parts = fullName.split(RegExp(r'\s+'));
    final family = parts.length > 1 ? parts.last : '';
    final given = parts.length > 1
        ? parts.sublist(0, parts.length - 1).join(' ')
        : fullName;
    var site = website.trim();
    if (site.isNotEmpty && !site.contains('://')) site = 'https://$site';
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-()]'), '');

    final lines = <String>[
      'BEGIN:VCARD',
      'VERSION:3.0',
      'N:${esc(family)};${esc(given)}',
      'FN:${esc(fullName)}',
      if (company.trim().isNotEmpty) 'ORG:${esc(company)}',
      if (cleanPhone.isNotEmpty) 'TEL:$cleanPhone',
      if (email.trim().isNotEmpty) 'EMAIL:${esc(email)}',
      if (site.isNotEmpty) 'URL:${esc(site)}',
      'END:VCARD',
    ];
    return lines.join('\r\n');
  }

  /// Geçmiş kaydını yeniden yazılabilir bir NDEF kaydına çevirir.
  static NdefRecord? fromHistory(
    NfcHistoryItem item, {
    String languageCode = 'en',
  }) {
    final Map<String, dynamic> data;
    try {
      data = Map<String, dynamic>.from(jsonDecode(item.content) as Map);
    } catch (_) {
      return null;
    }
    final service = NfcService.instance;
    String? value(String key) => data[key]?.toString();

    switch (item.type) {
      case NfcHistoryType.url:
        final url = value('url');
        return url == null ? null : service.createUriRecord(uri: url);
      case NfcHistoryType.phone:
        final phone = value('phone');
        return phone == null
            ? null
            : service.createUriRecord(uri: 'tel:$phone');
      case NfcHistoryType.email:
        final email = value('email');
        return email == null
            ? null
            : service.createUriRecord(uri: 'mailto:$email');
      case NfcHistoryType.location:
        final location = value('location');
        return location == null ? null : service.createUriRecord(uri: location);
      case NfcHistoryType.sms:
        final sms = value('sms');
        return sms == null ? null : service.createUriRecord(uri: sms);
      case NfcHistoryType.text:
        final text = value('text');
        return text == null
            ? null
            : service.createTextRecord(text: text, languageCode: languageCode);
      case NfcHistoryType.wifi:
        final buffer = StringBuffer('WIFI:');
        data.forEach((key, v) => buffer.write('$key:$v;'));
        return service.createMimeRecord(
          mimeType: 'application/vnd.wfa.wsc',
          data: Uint8List.fromList(utf8.encode(buffer.toString())),
        );
      case NfcHistoryType.vcard:
        final vcard = value('vcard');
        return vcard == null
            ? null
            : service.createMimeRecord(
                mimeType: 'text/x-vcard',
                data: Uint8List.fromList(utf8.encode(vcard)),
              );
      default:
        final content = value('content');
        final mimeType = value('mimeType');
        if (content == null || mimeType == null || mimeType.isEmpty) {
          return null;
        }
        return service.createMimeRecord(
          mimeType: mimeType,
          data: Uint8List.fromList(utf8.encode(content)),
        );
    }
  }

  /// Okunan veya yazılan kayıtları geçmişe ekler. Hatalar kullanıcı
  /// akışını bozmasın diye yutulur.
  static Future<void> saveToHistory(
    Iterable<NdefRecord> records, {
    required bool isWrite,
  }) async {
    for (final record in records) {
      try {
        final summary = summarize(record);
        if (isWrite) {
          await NfcHistoryHelper.saveWriteHistory(
            title: summary.title,
            type: summary.type,
            data: summary.data,
          );
        } else {
          await NfcHistoryHelper.saveReadHistory(
            title: summary.title,
            type: summary.type,
            data: summary.data,
          );
        }
      } catch (e) {
        debugPrint('History save failed: $e');
      }
    }
  }
}
