/// Premium özellik sabitleri ve kısıtlamalar
class PremiumFeatures {
  PremiumFeatures._();

  /// Premium ürün ID'si (iOS için) - Tüm özellikler
  static const String premiumProductId = 'pro_version';

  /// Reklamsız ürün ID'si (iOS için) - Sadece reklamları kaldırır
  static const String adFreeProductId = 'remove_ads';

  /// Premium fiyat
  static const String premiumPrice = '\$49.99';

  /// Reklamsız fiyat
  static const String adFreePrice = '\$0.99';

  /// Free kullanıcılar için izin verilen NFC veri tipleri
  static const List<String> freeUserAllowedTypes = [
    'URL', // Sadece URL yazabilirler
  ];

  /// Premium özelliklerin listesi
  static const List<PremiumFeature> features = [
    PremiumFeature(
      icon: 'edit_note',
      titleKey: 'premium.features.all_nfc_types.title',
      descriptionKey: 'premium.features.all_nfc_types.description',
    ),
    PremiumFeature(
      icon: 'history',
      titleKey: 'premium.features.unlimited_history.title',
      descriptionKey: 'premium.features.unlimited_history.description',
    ),
    PremiumFeature(
      icon: 'block',
      titleKey: 'premium.features.no_ads.title',
      descriptionKey: 'premium.features.no_ads.description',
    ),
    PremiumFeature(
      icon: 'priority_high',
      titleKey: 'premium.features.priority_support.title',
      descriptionKey: 'premium.features.priority_support.description',
    ),
    PremiumFeature(
      icon: 'update',
      titleKey: 'premium.features.lifetime_updates.title',
      descriptionKey: 'premium.features.lifetime_updates.description',
    ),
  ];
}

/// Premium özellik modeli
class PremiumFeature {
  final String icon;
  final String titleKey;
  final String descriptionKey;

  const PremiumFeature({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
  });
}
