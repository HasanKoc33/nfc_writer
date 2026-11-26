/// AppConstants enum
enum AppConstants {
  productIdAndroid('com.firesoft.nfcWriter.removeAds'),
  productIdiOS('com.firesoft.nfcWriter.removeAds'),
  productIdProAndroid('com.firesoft.nfcWriter.pro'),
  // App Store Connect'te Pro ürününün Product ID'si.
  productIdProiOS('pro_version'),
  premiumKey('is_premium'),
  privacyPolicy('https://firesoftyazilim.com/privacy-policy'),
  termsAndCondition('https://firesoftyazilim.com/terms'),
  ;

  const AppConstants(this.value);

  /// AppConstants degeri
  final String value;
}
