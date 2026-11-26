# Firebase Cloud Messaging (FCM) Kurulum Rehberi

## Genel Bakış
Bu proje Firebase Cloud Messaging (FCM) ile entegre edilmiştir. Uygulama açıldığında kullanıcılar otomatik olarak FCM'e kaydedilir ve son uygulama açılış zamanı takip edilir.

## Yapılan Değişiklikler

### 1. Bağımlılıklar (`pubspec.yaml`)
```yaml
firebase_messaging: ^15.1.6
flutter_local_notifications: ^18.0.1
```

### 2. Oluşturulan Servisler

#### `FirebaseMessagingService` (`lib/core/services/firebase_messaging_service.dart`)
- FCM token yönetimi
- Bildirim izinleri isteme
- Foreground, background ve terminated durumlarında bildirim yönetimi
- Son uygulama açılış zamanını kaydetme
- Topic subscription/unsubscription

**Önemli Metodlar:**
- `initialize()`: FCM'i başlatır ve izinleri ister
- `fcmToken`: Mevcut FCM token'ını döndürür
- `updateLastAppOpenTime()`: Son açılış zamanını günceller
- `getLastAppOpenTime()`: Son açılış zamanını getirir
- `subscribeToTopic(String topic)`: Bir topic'e abone olur
- `unsubscribeFromTopic(String topic)`: Bir topic'ten çıkar

#### `NotificationService` (`lib/core/services/notification_service.dart`)
- Yerel bildirim gösterimi
- FCM bildirimlerini yerel bildirimlere dönüştürme
- Android ve iOS için platform-specific konfigürasyon

#### `UserActivityRepository` (`lib/data/repositories/user_activity_repository.dart`)
- Kullanıcı aktivitesini takip etme
- FCM token ve son açılış zamanını kaydetme
- Unique user ID oluşturma ve saklama

### 3. Platform Konfigürasyonları

#### Android (`android/app/src/main/AndroidManifest.xml`)
- `POST_NOTIFICATIONS` izni eklendi
- FCM servisi konfigüre edildi
- Default notification channel tanımlandı

#### iOS (`ios/Runner/Info.plist`)
- Background modes eklendi (`fetch`, `remote-notification`)
- Push notification desteği aktif

### 4. Main.dart Güncellemeleri
```dart
await NotificationService().initialize();
await FirebaseMessagingService().initialize();
await UserActivityRepository().registerUserActivity();
```

## Kullanım

### FCM Token'ı Alma
```dart
final token = FirebaseMessagingService().fcmToken;
print('FCM Token: $token');
```

### Son Uygulama Açılış Zamanını Kontrol Etme
```dart
final lastOpen = await FirebaseMessagingService().getLastAppOpenTime();
if (lastOpen != null) {
  final difference = DateTime.now().difference(lastOpen);
  print('Uygulama ${difference.inDays} gün önce açılmış');
}
```

### Topic'lere Abone Olma
```dart
await FirebaseMessagingService().subscribeToTopic('inactive_users');
await FirebaseMessagingService().subscribeToTopic('all_users');
```

## Backend Entegrasyonu

### İnaktif Kullanıcılara Bildirim Gönderme

Backend tarafında, inaktif kullanıcıları tespit etmek ve bildirim göndermek için:

1. **Kullanıcı Verilerini Saklama**
   - `user_id`: Unique kullanıcı kimliği
   - `fcm_token`: Firebase Cloud Messaging token'ı
   - `last_app_open`: Son uygulama açılış zamanı
   - `platform`: iOS veya Android

2. **İnaktif Kullanıcıları Tespit Etme**
```javascript
// Node.js örneği
const inactiveThreshold = 7; // 7 gün
const now = new Date();
const inactiveUsers = users.filter(user => {
  const lastOpen = new Date(user.last_app_open);
  const daysDiff = (now - lastOpen) / (1000 * 60 * 60 * 24);
  return daysDiff >= inactiveThreshold;
});
```

3. **FCM ile Bildirim Gönderme**
```javascript
const admin = require('firebase-admin');

async function sendNotificationToInactiveUsers(users) {
  const messages = users.map(user => ({
    token: user.fcm_token,
    notification: {
      title: 'NFC Writer\'ı Özlediniz mi?',
      body: 'Uzun zamandır görüşemedik! Yeni özelliklerimizi keşfedin.',
    },
    data: {
      type: 'inactive_user_reminder',
      user_id: user.user_id,
    },
  }));

  const response = await admin.messaging().sendAll(messages);
  console.log(`${response.successCount} bildirim gönderildi`);
}
```

4. **Cron Job ile Otomatik Kontrol**
```javascript
// Her gün 10:00'da çalışacak cron job
const cron = require('node-cron');

cron.schedule('0 10 * * *', async () => {
  console.log('İnaktif kullanıcılar kontrol ediliyor...');
  const inactiveUsers = await getInactiveUsers();
  if (inactiveUsers.length > 0) {
    await sendNotificationToInactiveUsers(inactiveUsers);
  }
});
```

## Firebase Console Konfigürasyonu

### 1. Firebase Projesi Ayarları
- Firebase Console'da projenizi açın
- Project Settings > Cloud Messaging
- Server key'i backend'de kullanın

### 2. APNs Sertifikası (iOS için)
- Apple Developer hesabınızdan APNs sertifikası oluşturun
- Firebase Console > Project Settings > Cloud Messaging > iOS app configuration
- APNs sertifikasını yükleyin

### 3. Test Bildirimi Gönderme
Firebase Console'dan test bildirimi:
1. Cloud Messaging > Send your first message
2. Notification title ve text girin
3. Test on device seçin
4. FCM token'ı girin
5. Test butonuna tıklayın

## Önemli Notlar

1. **İzinler**: Android 13+ için `POST_NOTIFICATIONS` izni runtime'da istenir
2. **Background Handler**: Background mesajlar için `@pragma('vm:entry-point')` gereklidir
3. **Token Yenileme**: FCM token'ları yenilenebilir, `onTokenRefresh` listener'ı bunu yakalar
4. **Platform Farklılıkları**: iOS'ta APNs sertifikası gereklidir
5. **Notification Channel**: Android'de notification channel tanımlanmalıdır

## Sorun Giderme

### Bildirimler Gelmiyor
1. FCM token'ının doğru alındığını kontrol edin
2. Firebase Console'da doğru server key kullanıldığını doğrulayın
3. iOS için APNs sertifikasının yüklendiğini kontrol edin
4. AndroidManifest.xml'de gerekli izinlerin olduğunu doğrulayın

### Token Null Geliyor
1. `flutter pub get` komutunu çalıştırın
2. Uygulamayı temizleyip yeniden derleyin
3. Firebase konfigürasyonunun doğru olduğunu kontrol edin

## Gelecek Geliştirmeler

- [ ] Backend API endpoint'leri oluşturma
- [ ] Kullanıcı segmentasyonu
- [ ] A/B testing için farklı bildirim mesajları
- [ ] Bildirim analytics entegrasyonu
- [ ] Rich notifications (resim, aksiyon butonları)
