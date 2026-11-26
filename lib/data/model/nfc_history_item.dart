import 'package:uuid/uuid.dart';

class NfcHistoryItem {
  final String id;
  final String title;
  final String type;
  final String content;
  final DateTime timestamp;
  final String category;
  final Map<String, dynamic>? metadata;

  NfcHistoryItem({
    String? id,
    required this.title,
    required this.type,
    required this.content,
    DateTime? timestamp,
    required this.category,
    this.metadata,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
      'metadata': metadata,
    };
  }

  factory NfcHistoryItem.fromJson(Map<String, dynamic> json) {
    return NfcHistoryItem(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      category: json['category'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  NfcHistoryItem copyWith({
    String? id,
    String? title,
    String? type,
    String? content,
    DateTime? timestamp,
    String? category,
    Map<String, dynamic>? metadata,
  }) {
    return NfcHistoryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      metadata: metadata ?? this.metadata,
    );
  }

  String getIconName() {
    switch (type) {
      case 'url':
        return 'link';
      case 'text':
        return 'text_fields';
      case 'wifi':
        return 'wifi';
      case 'phone':
        return 'phone';
      case 'email':
        return 'email';
      case 'location':
        return 'location_on';
      case 'sms':
        return 'sms';
      case 'vcard':
        return 'contact_page';
      default:
        return 'nfc';
    }
  }
}

class NfcHistoryType {
  static const String url = 'url';
  static const String text = 'text';
  static const String wifi = 'wifi';
  static const String phone = 'phone';
  static const String email = 'email';
  static const String location = 'location';
  static const String sms = 'sms';
  static const String vcard = 'vcard';
  static const String other = 'other';
}

class NfcHistoryCategory {
  static const String read = 'read';
  static const String write = 'write';
}
