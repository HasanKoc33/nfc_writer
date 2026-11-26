# Firebase Analytics Kurulum ve Kullanım Rehberi

## Genel Bakış
Firebase Analytics, kullanıcı davranışlarını izlemek ve uygulama performansını analiz etmek için kurulmuştur. Tüm önemli kullanıcı etkileşimleri otomatik olarak kaydedilir.

## Yapılan Değişiklikler

### 1. Bağımlılık (`pubspec.yaml`)
```yaml
firebase_analytics: ^11.4.0
```

### 2. Oluşturulan Dosyalar

#### `AnalyticsService` (`lib/core/services/analytics_service.dart`)
Ana analytics servisi. Tüm Firebase Analytics işlemlerini yönetir.

**Özellikler:**
- Singleton pattern ile tek instance
- FirebaseAnalyticsObserver ile otomatik sayfa takibi
- 25+ önceden tanımlanmış event metodu
- Custom event desteği
- User properties yönetimi

#### `AnalyticsMixin` (`lib/core/mixins/analytics_mixin.dart`)
StatefulWidget'lara eklenebilir mixin. Otomatik ekran takibi sağlar.

**Kullanım:**
```dart
class MyScreenState extends State<MyScreen> with AnalyticsMixin {
  void _onButtonPressed() {
    logButtonClick('submit_button');
  }
}
```

#### `AnalyticsHelper` (`lib/core/utils/analytics_helper.dart`)
Static metodlarla kolay erişim sağlar.

**Kullanım:**
```dart
await AnalyticsHelper.trackNFCRead(
  nfcType: 'NDEF',
  dataSize: 256,
);
```

### 3. Main.dart Güncellemeleri
```dart
// Analytics başlatma
await AnalyticsService().logAppOpen();

// MaterialApp'e observer ekleme
MaterialApp(
  navigatorObservers: [AnalyticsService().observer],
  // ...
)
```

## Kullanılabilir Event'ler

### NFC İşlemleri
```dart
// NFC Okuma
await AnalyticsHelper.trackNFCRead(
  nfcType: 'NDEF',
  dataSize: 128,
);

// NFC Yazma
await AnalyticsHelper.trackNFCWrite(
  nfcType: 'NDEF',
  writeType: 'URL',
  dataSize: 64,
);

// NFC Hatası
await AnalyticsHelper.trackNFCError(
  errorType: 'read_failed',
  errorMessage: 'Tag not found',
);
```

### Kullanıcı Etkileşimleri
```dart
// Buton Tıklama
AnalyticsService().logButtonClick(
  buttonName: 'write_nfc_button',
  screenName: 'HomeScreen',
);

// Özellik Kullanımı
AnalyticsService().logFeatureUsage(
  featureName: 'wifi_setup',
  additionalParams: {'ssid': 'MyNetwork'},
);

// Arama
await AnalyticsHelper.trackSearch('NFC tags');

// Paylaşım
await AnalyticsHelper.trackShare(
  contentType: 'nfc_data',
  itemId: 'tag_123',
  method: 'whatsapp',
);
```

### Uygulama Ayarları
```dart
// Dil Değişikliği
await AnalyticsHelper.trackLanguageChange('tr');

// Tema Değişikliği
await AnalyticsHelper.trackThemeChange('dark');
```

### WiFi İşlemleri
```dart
await AnalyticsHelper.trackWifiConnection(
  ssid: 'MyNetwork',
  success: true,
);
```

### Satın Alma İşlemleri
```dart
await AnalyticsHelper.trackPurchase(
  productId: 'pro_version',
  price: 9.99,
  currency: 'USD',
);
```

### Reklam İşlemleri
```dart
// Reklam Gösterimi
await AnalyticsHelper.trackAdImpression(
  adType: 'banner',
  adPlacement: 'home_screen_bottom',
);

// Reklam Tıklama
await AnalyticsHelper.trackAdClick(
  adType: 'interstitial',
  adPlacement: 'after_nfc_write',
);
```

### Hata Takibi
```dart
AnalyticsService().logError(
  errorType: 'network_error',
  errorMessage: 'Connection timeout',
  stackTrace: stackTrace.toString(),
);
```

### Kullanıcı Özellikleri
```dart
// User ID Ayarlama
await AnalyticsHelper.setUserId('user_12345');

// User Property Ayarlama
await AnalyticsHelper.setUserProperty(
  name: 'user_type',
  value: 'premium',
);

await AnalyticsHelper.setUserProperty(
  name: 'preferred_language',
  value: 'tr',
);
```

### Ekran Takibi
```dart
// Manuel ekran takibi
await AnalyticsService().logScreenView(
  screenName: 'SettingsScreen',
  screenClass: 'SettingsScreen',
);

// Otomatik takip için AnalyticsMixin kullanın
```

### Custom Event'ler
```dart
await AnalyticsHelper.trackCustomEvent(
  eventName: 'special_feature_used',
  parameters: {
    'feature_id': 'advanced_nfc',
    'user_level': 5,
    'timestamp': DateTime.now().toIso8601String(),
  },
);
```

## Ekranlara Analytics Ekleme

### Yöntem 1: AnalyticsMixin Kullanımı (Önerilen)
```dart
import 'package:nfc_writer/core/mixins/analytics_mixin.dart';

class HomeScreenState extends State<HomeScreen> with AnalyticsMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: ElevatedButton(
        onPressed: () {
          logButtonClick('start_nfc_read');
          // NFC okuma işlemi
        },
        child: Text('Read NFC'),
      ),
    );
  }
}
```

### Yöntem 2: Manuel Takip
```dart
import 'package:nfc_writer/core/services/analytics_service.dart';

class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final _analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _analytics.logScreenView(
      screenName: 'MyScreen',
      screenClass: 'MyScreen',
    );
  }

  void _onActionPerformed() {
    _analytics.logButtonClick(
      buttonName: 'action_button',
      screenName: 'MyScreen',
    );
  }
}
```

## NFC İşlemlerine Analytics Ekleme

### Reading Screen Örneği
```dart
import 'package:nfc_writer/core/utils/analytics_helper.dart';

void _startNFCReading() async {
  try {
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        // NFC okuma başarılı
        await AnalyticsHelper.trackNFCRead(
          nfcType: 'NDEF',
          dataSize: tag.data.length,
        );
        
        // Veri işleme...
      },
    );
  } catch (e) {
    // Hata durumunda
    await AnalyticsHelper.trackNFCError(
      errorType: 'read_error',
      errorMessage: e.toString(),
    );
  }
}
```

### Writing Screen Örneği
```dart
void _writeNFC(String data, String type) async {
  try {
    // NFC yazma işlemi
    await writeToNFC(data);
    
    // Analytics kaydı
    await AnalyticsHelper.trackNFCWrite(
      nfcType: 'NDEF',
      writeType: type, // 'URL', 'TEXT', 'WIFI', etc.
      dataSize: data.length,
    );
  } catch (e) {
    await AnalyticsHelper.trackNFCError(
      errorType: 'write_error',
      errorMessage: e.toString(),
    );
  }
}
```

## Firebase Console'da Analytics Görüntüleme

### 1. Firebase Console'a Giriş
1. [Firebase Console](https://console.firebase.google.com/) adresine gidin
2. Projenizi seçin
3. Sol menüden **Analytics** > **Dashboard** seçin

### 2. Önemli Metrikler
- **Active Users**: Aktif kullanıcı sayısı
- **Events**: Toplam event sayısı
- **Retention**: Kullanıcı elde tutma oranı
- **User Properties**: Kullanıcı özellikleri dağılımı

### 3. Custom Event'leri Görüntüleme
1. Analytics > Events
2. Custom event'lerinizi listede göreceksiniz
3. Her event'e tıklayarak detaylı analiz yapabilirsiniz

### 4. Funnel Analizi
1. Analytics > Funnels
2. Kullanıcı akışlarını analiz edin
3. Örnek: app_open → nfc_read → nfc_write

### 5. Audience Oluşturma
1. Analytics > Audiences
2. Belirli davranışlara göre kullanıcı grupları oluşturun
3. Örnek: "Son 7 günde NFC yazan kullanıcılar"

## Debug Mode

### Android
```bash
adb shell setprop debug.firebase.analytics.app com.yourpackage.nfc_writer
```

### iOS
1. Xcode'da scheme düzenleyin
2. Arguments > Arguments Passed On Launch
3. `-FIRAnalyticsDebugEnabled` ekleyin

### DebugView'da Kontrol
1. Firebase Console > Analytics > DebugView
2. Gerçek zamanlı event'leri görün
3. Test sırasında event'lerin doğru gönderildiğini doğrulayın

## Best Practices

### 1. Event İsimlendirme
- Küçük harf kullanın: `nfc_read` ✅, `NFC_Read` ❌
- Alt çizgi kullanın: `button_click` ✅, `buttonClick` ❌
- Maksimum 40 karakter
- Anlamlı isimler: `purchase_completed` ✅, `event1` ❌

### 2. Parameter İsimlendirme
- Maksimum 40 karakter
- Küçük harf ve alt çizgi
- Maksimum 100 unique parameter per event

### 3. Event Limitleri
- Maksimum 500 farklı event tipi
- Günlük sınırsız event
- Gerçek zamanlı: Son 30 dakika

### 4. User Properties
- Maksimum 25 user property
- String değerler maksimum 36 karakter
- Değişmeyen özellikler için kullanın (user_type, subscription_level)

### 5. Performance
- Batch işlemler yapın
- Çok sık event göndermeyin (örn: her scroll'da)
- Önemli event'lere odaklanın

## Yaygın Kullanım Senaryoları

### Senaryo 1: Kullanıcı Akışı Analizi
```dart
// 1. Uygulama açıldı
await AnalyticsService().logAppOpen();

// 2. Ana ekran görüntülendi
await AnalyticsService().logScreenView(screenName: 'HomeScreen');

// 3. NFC okuma başlatıldı
logButtonClick('start_nfc_read');

// 4. NFC başarıyla okundu
await AnalyticsHelper.trackNFCRead(nfcType: 'NDEF', dataSize: 128);

// 5. Veri paylaşıldı
await AnalyticsHelper.trackShare(
  contentType: 'nfc_data',
  itemId: 'tag_123',
  method: 'whatsapp',
);
```

### Senaryo 2: Hata Analizi
```dart
try {
  await performNFCOperation();
} catch (e, stackTrace) {
  await AnalyticsService().logError(
    errorType: e.runtimeType.toString(),
    errorMessage: e.toString(),
    stackTrace: stackTrace.toString(),
  );
  
  // Kullanıcıya hata göster
}
```

### Senaryo 3: A/B Testing Hazırlığı
```dart
// Kullanıcıyı gruplara ayır
final userGroup = Random().nextBool() ? 'group_a' : 'group_b';
await AnalyticsHelper.setUserProperty(
  name: 'ab_test_group',
  value: userGroup,
);

// Feature kullanımını takip et
await AnalyticsHelper.trackFeatureUsage(
  featureName: 'new_ui_design',
  additionalParams: {'group': userGroup},
);
```

### Senaryo 4: Conversion Tracking
```dart
// Ücretsiz kullanıcı
await AnalyticsHelper.setUserProperty(
  name: 'user_type',
  value: 'free',
);

// Pro versiyona geçiş
await AnalyticsHelper.trackPurchase(
  productId: 'pro_version',
  price: 9.99,
  currency: 'USD',
);

await AnalyticsHelper.setUserProperty(
  name: 'user_type',
  value: 'premium',
);
```

## Entegrasyon Kontrol Listesi

- [x] firebase_analytics dependency eklendi
- [x] AnalyticsService oluşturuldu
- [x] Main.dart'ta initialize edildi
- [x] NavigatorObserver eklendi
- [x] AnalyticsMixin oluşturuldu
- [x] AnalyticsHelper oluşturuldu
- [ ] Tüm ekranlara analytics eklendi
- [ ] NFC işlemlerine tracking eklendi
- [ ] Satın alma işlemlerine tracking eklendi
- [ ] Reklam event'leri eklendi
- [ ] Hata tracking eklendi
- [ ] Firebase Console'da test edildi
- [ ] DebugView ile doğrulandı

## Sonraki Adımlar

1. **Ekranlara Analytics Ekleyin**
   - Her ekrana `AnalyticsMixin` ekleyin
   - Önemli butonlara `logButtonClick` ekleyin

2. **NFC İşlemlerini İzleyin**
   - Reading screen'e `trackNFCRead` ekleyin
   - Writing screen'e `trackNFCWrite` ekleyin
   - Hata durumlarında `trackNFCError` ekleyin

3. **Kullanıcı Özelliklerini Ayarlayın**
   - User ID'yi kaydedin
   - Dil, tema gibi tercihleri user property olarak kaydedin
   - Premium/Free durumunu takip edin

4. **Test Edin**
   - Debug mode'u aktif edin
   - DebugView'da event'leri kontrol edin
   - Gerçek cihazda test edin

5. **Analiz Edin**
   - Firebase Console'da düzenli olarak metrikleri inceleyin
   - Kullanıcı davranışlarını analiz edin
   - Funnel'ları optimize edin

## Sorun Giderme

### Event'ler Firebase'e Gitmiyor
1. İnternet bağlantısını kontrol edin
2. Firebase konfigürasyonunu doğrulayın
3. Debug mode'u aktif edin ve DebugView'da kontrol edin
4. `flutter pub get` çalıştırın

### DebugView'da Event Görünmüyor
1. Debug mode'un aktif olduğunu doğrulayın
2. Uygulamayı yeniden başlatın
3. Doğru cihazı seçtiğinizden emin olun

### Event İsimleri Geçersiz
1. Küçük harf kullanın
2. Özel karakterler kullanmayın (sadece alt çizgi)
3. 40 karakterden kısa tutun
4. Sayı ile başlamayın

## Faydalı Linkler

- [Firebase Analytics Documentation](https://firebase.google.com/docs/analytics)
- [FlutterFire Analytics](https://firebase.flutter.dev/docs/analytics/overview)
- [Analytics Events Reference](https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event)
- [Best Practices](https://firebase.google.com/docs/analytics/best-practices)
