import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

/// Mağaza değerlendirme isteği.
///
/// Sistemin kendi değerlendirme penceresini kullanır. iOS bu pencereyi
/// yılda en fazla 3 kez, Google Play de kendi kotasına göre gösterir;
/// fazla çağrıları sessizce yok sayar. Bu yüzden sık çağırmak kullanıcıyı
/// rahatsız etmez, ama her çağrıda pencere çıkacağı garanti değildir.
class ReviewService {
  ReviewService._();

  static final ReviewService instance = ReviewService._();

  final InAppReview _inAppReview = InAppReview.instance;

  /// Aynı oturumda birden fazla istek göndermemek için.
  bool _requestedThisSession = false;

  Future<void> request() async {
    if (_requestedThisSession) return;
    _requestedThisSession = true;
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      }
    } catch (e) {
      debugPrint('Review request failed: $e');
    }
  }
}
