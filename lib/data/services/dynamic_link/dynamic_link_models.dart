/// Firesoft Redirection API'deki Link nesnesi.
class DynamicLink {
  const DynamicLink({
    required this.code,
    required this.shortUrl,
    required this.title,
    required this.target,
    required this.targetIos,
    required this.targetAndroid,
    required this.active,
    required this.hits,
    required this.redirects,
    required this.uniqueVisitors,
    this.createdAt,
    this.updatedAt,
    this.lastHitAt,
  });

  final String code;
  final String shortUrl;
  final String title;
  final String target;
  final String targetIos;
  final String targetAndroid;
  final bool active;
  final int hits;
  final int redirects;
  final int uniqueVisitors;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastHitAt;

  factory DynamicLink.fromJson(Map<String, dynamic> json) {
    return DynamicLink(
      code: json['code']?.toString() ?? '',
      shortUrl: json['short_url']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      target: json['target']?.toString() ?? '',
      targetIos: json['target_ios']?.toString() ?? '',
      targetAndroid: json['target_android']?.toString() ?? '',
      active: json['active'] == true,
      hits: _int(json['hits']),
      redirects: _int(json['redirects']),
      uniqueVisitors: _int(json['unique_visitors']),
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
      lastHitAt: _date(json['last_hit_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'short_url': shortUrl,
    'title': title,
    'target': target,
    'target_ios': targetIos,
    'target_android': targetAndroid,
    'active': active,
    'hits': hits,
    'redirects': redirects,
    'unique_visitors': uniqueVisitors,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'last_hit_at': lastHitAt?.toIso8601String(),
  };
}

class LinkStatsTotals {
  const LinkStatsTotals({
    required this.hits,
    required this.redirects,
    required this.uniqueVisitors,
    required this.today,
    required this.last7Days,
    this.lastHitAt,
  });

  final int hits;
  final int redirects;
  final int uniqueVisitors;
  final int today;
  final int last7Days;
  final DateTime? lastHitAt;

  factory LinkStatsTotals.fromJson(Map<String, dynamic> json) {
    return LinkStatsTotals(
      hits: _int(json['hits']),
      redirects: _int(json['redirects']),
      uniqueVisitors: _int(json['unique_visitors']),
      today: _int(json['today']),
      last7Days: _int(json['last_7_days']),
      lastHitAt: _date(json['last_hit_at']),
    );
  }
}

class LinkStatsBucket {
  const LinkStatsBucket(this.key, this.count);

  final String key;
  final int count;
}

/// GET /links/{code}/stats yanıtı.
class LinkStats {
  const LinkStats({
    required this.totals,
    required this.daily,
    required this.devices,
    required this.os,
    required this.browsers,
    required this.referers,
  });

  final LinkStatsTotals totals;
  final List<LinkStatsBucket> daily;
  final List<LinkStatsBucket> devices;
  final List<LinkStatsBucket> os;
  final List<LinkStatsBucket> browsers;
  final List<LinkStatsBucket> referers;

  factory LinkStats.fromJson(Map<String, dynamic> json) {
    List<LinkStatsBucket> buckets(dynamic list, String keyField) {
      if (list is! List) return const [];
      return [
        for (final item in list)
          if (item is Map)
            LinkStatsBucket(
              item[keyField]?.toString() ?? '',
              _int(item['count']),
            ),
      ];
    }

    final breakdown = json['breakdown'] is Map
        ? Map<String, dynamic>.from(json['breakdown'] as Map)
        : <String, dynamic>{};
    return LinkStats(
      totals: LinkStatsTotals.fromJson(
        json['totals'] is Map
            ? Map<String, dynamic>.from(json['totals'] as Map)
            : const {},
      ),
      daily: buckets(json['daily'], 'date'),
      devices: buckets(breakdown['device'], 'key'),
      os: buckets(breakdown['os'], 'key'),
      browsers: buckets(breakdown['browser'], 'key'),
      referers: buckets(breakdown['referer'], 'key'),
    );
  }
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}
