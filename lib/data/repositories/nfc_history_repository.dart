import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/nfc_history_item.dart';

class NfcHistoryRepository {
  static final NfcHistoryRepository _instance = NfcHistoryRepository._internal();
  factory NfcHistoryRepository() => _instance;
  NfcHistoryRepository._internal();

  static const String _historyKey = 'nfc_history';
  static const int _maxHistoryItems = 100;

  Future<List<NfcHistoryItem>> getAllHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(_historyKey);
      
      if (historyJson == null || historyJson.isEmpty) {
        return [];
      }

      final List<dynamic> historyList = jsonDecode(historyJson);
      return historyList
          .map((item) => NfcHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading history: $e');
      }
      return [];
    }
  }

  Future<List<NfcHistoryItem>> getReadHistory() async {
    final allHistory = await getAllHistory();
    return allHistory
        .where((item) => item.category == NfcHistoryCategory.read)
        .toList();
  }

  Future<List<NfcHistoryItem>> getWriteHistory() async {
    final allHistory = await getAllHistory();
    return allHistory
        .where((item) => item.category == NfcHistoryCategory.write)
        .toList();
  }

  Future<List<NfcHistoryItem>> getHistoryByType(String type) async {
    final allHistory = await getAllHistory();
    return allHistory.where((item) => item.type == type).toList();
  }

  Future<bool> saveHistoryItem(NfcHistoryItem item) async {
    try {
      final allHistory = await getAllHistory();
      
      allHistory.insert(0, item);
      
      if (allHistory.length > _maxHistoryItems) {
        allHistory.removeRange(_maxHistoryItems, allHistory.length);
      }

      return await _saveHistory(allHistory);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving history item: $e');
      }
      return false;
    }
  }

  Future<bool> saveReadHistory(NfcHistoryItem item) async {
    if (item.category != NfcHistoryCategory.read) {
      item = item.copyWith(category: NfcHistoryCategory.read);
    }
    return await saveHistoryItem(item);
  }

  Future<bool> saveWriteHistory(NfcHistoryItem item) async {
    if (item.category != NfcHistoryCategory.write) {
      item = item.copyWith(category: NfcHistoryCategory.write);
    }
    return await saveHistoryItem(item);
  }

  Future<bool> deleteHistoryItem(String id) async {
    try {
      final allHistory = await getAllHistory();
      allHistory.removeWhere((item) => item.id == id);
      return await _saveHistory(allHistory);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting history item: $e');
      }
      return false;
    }
  }

  Future<bool> clearHistory(String category) async {
    try {
      if (category == 'all') {
        return await _saveHistory([]);
      }

      final allHistory = await getAllHistory();
      final filteredHistory = allHistory
          .where((item) => item.category != category)
          .toList();
      return await _saveHistory(filteredHistory);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing history: $e');
      }
      return false;
    }
  }

  Future<bool> _saveHistory(List<NfcHistoryItem> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(
        history.map((item) => item.toJson()).toList(),
      );
      return await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving history to storage: $e');
      }
      return false;
    }
  }

  Future<int> getHistoryCount({String? category}) async {
    if (category == null) {
      final allHistory = await getAllHistory();
      return allHistory.length;
    }

    if (category == NfcHistoryCategory.read) {
      final readHistory = await getReadHistory();
      return readHistory.length;
    }

    if (category == NfcHistoryCategory.write) {
      final writeHistory = await getWriteHistory();
      return writeHistory.length;
    }

    return 0;
  }

  Future<List<NfcHistoryItem>> searchHistory(String query, {String? category}) async {
    final history = category == null
        ? await getAllHistory()
        : category == NfcHistoryCategory.read
            ? await getReadHistory()
            : await getWriteHistory();

    if (query.isEmpty) {
      return history;
    }

    final lowerQuery = query.toLowerCase();
    return history.where((item) {
      return item.title.toLowerCase().contains(lowerQuery) ||
          item.content.toLowerCase().contains(lowerQuery) ||
          item.type.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
