import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/dynamic_link/dynamic_link_models.dart';
import '../services/dynamic_link/dynamic_link_service.dart';

/// Bu cihazda oluşturulan dinamik linkleri tutar.
///
/// Uygulama tek bir API anahtarı kullandığı için sunucu tüm kullanıcıların
/// linklerini aynı anahtar altında görür. Kullanıcıya yalnızca kendi
/// linklerini göstermek için oluşturulan kodlar cihazda saklanır ve liste
/// bu kodlardan kurulur.
class DynamicLinkRepository {
  DynamicLinkRepository._();

  static final DynamicLinkRepository instance = DynamicLinkRepository._();

  static const String _storageKey = 'dynamic_links_v1';

  final DynamicLinkService _service = DynamicLinkService.instance;

  /// Liste değiştiğinde (ekleme, silme, güncelleme) dinleyicileri uyarır.
  final ValueNotifier<int> revision = ValueNotifier(0);

  Future<List<DynamicLink>> cachedLinks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final item in list)
          DynamicLink.fromJson(Map<String, dynamic>.from(item as Map)),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<DynamicLink> links) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode([for (final link in links) link.toJson()]),
    );
    revision.value++;
  }

  Future<DynamicLink> create({
    required String target,
    String targetIos = '',
    String targetAndroid = '',
    String title = '',
  }) async {
    final link = await _service.createLink(
      target: target,
      targetIos: targetIos,
      targetAndroid: targetAndroid,
      title: title,
    );
    final links = await cachedLinks();
    await _save([link, ...links.where((l) => l.code != link.code)]);
    return link;
  }

  /// Sunucudan güncel sayaçları çeker. Sunucuda silinmiş linkler listeden
  /// çıkarılır; ağ hatasında önbellekteki liste korunur.
  Future<List<DynamicLink>> refresh() async {
    final links = await cachedLinks();
    final refreshed = <DynamicLink>[];
    var changed = false;
    for (final link in links) {
      try {
        refreshed.add(await _service.getLink(link.code));
        changed = true;
      } on DynamicLinkException catch (e) {
        if (e.code == 'not_found') {
          changed = true;
          continue;
        }
        refreshed.add(link);
      }
    }
    if (changed) await _save(refreshed);
    return refreshed;
  }

  Future<DynamicLink> update(
    String code, {
    String? target,
    String? targetIos,
    String? targetAndroid,
    String? title,
    bool? active,
  }) async {
    final updated = await _service.updateLink(
      code,
      target: target,
      targetIos: targetIos,
      targetAndroid: targetAndroid,
      title: title,
      active: active,
    );
    final links = await cachedLinks();
    await _save([for (final link in links) link.code == code ? updated : link]);
    return updated;
  }

  Future<void> delete(String code) async {
    try {
      await _service.deleteLink(code);
    } on DynamicLinkException catch (e) {
      if (e.code != 'not_found') rethrow;
    }
    final links = await cachedLinks();
    await _save(links.where((l) => l.code != code).toList());
  }

  Future<LinkStats> stats(String code, {int days = 30}) {
    return _service.getStats(code, days: days);
  }
}
