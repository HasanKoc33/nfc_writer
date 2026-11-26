---
name: project-nfc-writer
description: NFC Writer iOS app — architecture, IAP setup, ASO metadata, key bugs fixed
metadata:
  type: project
---

Flutter NFC tag reader/writer app (iOS + Android) — published on App Store.

**App structure:**
- `lib/main.dart` → entry point, uses `MyApp` widget
- `lib/core/app/app.dart` → `App` widget (dead code) but hosts `purchaseStreamController<PurchaseDetails>`
- IAP: `lib/data/services/in_app_purchase/in_app_purchase_helper.dart`
- Premium key: `AppConstants.premiumKey.value` = `'is_premium'` (SharedPreferences)
- Product IDs: `com.firesoft.nfcWriter.removeAds` (remove ads, $0.99), `com.firesoft.nfcWriter.pro` (pro, $49.99 — needs App Store Connect setup)
- Ads: `lib/data/services/app_ads_service.dart`
- Translations: `assets/translations/` — 12 languages (en-US, tr-TR, de-DE, fr-FR, ar-SA, ja-JP, ko-KR, ru-RU, es-ES, it-IT, el-GR, zh-TW)
- ASO metadata: `ios/fastlane/metadata/` — 12 language folders

**Why:** Major session to fix all critical bugs and update ASO.

**How to apply:** The `com.firesoft.nfcWriter.pro` product ID needs to be created in App Store Connect for the Pro Version button to work. The remove ads product already exists.

**Key fixes applied (2026-06-04):**
- Premium key mismatch fixed: `setSubscription`/`getSubscription` now use `AppConstants.premiumKey.value` = `'is_premium'`
- `_isPremiumUser()` in writing_screen_mixin now calls `InAppPurchaseHelper().getSubscription()`
- `buyConsumable` → `buyNonConsumable` for one-time purchases
- WiFi dialog wrapped in StatefulBuilder (was not reactive)
- Stream subscription leak fixed in HomeScreen
- `isShowProgress` setState calls fixed in ProVersiyonScreen mixin
- All hardcoded Turkish strings replaced with `.tr()` localization keys
- New `common` section added to all 12 translation files
- New `nfc.write.*` and `nfc.scan.ios_*` keys added to all 12 translation files
- ASO keywords completely rewritten (removed NFC prefix repetition)
- ASO subtitles differentiated from app names
- Release notes made descriptive (vs generic "system update")
- All `print()` statements removed from UI layer
