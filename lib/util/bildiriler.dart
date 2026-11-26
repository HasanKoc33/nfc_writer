import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Bildirim tipleri
enum BildiriType {
  /// Başarılı
  success(
      icon: Icons.check_circle_outline,
      color: Colors.green,
      titleKey: 'common.success',
      showButton: true),

  /// Hata
  error(
      icon: Icons.error_outline,
      color: Colors.red,
      titleKey: 'common.error',
      showButton: true),

  /// Uyarı
  warning(
      icon: Icons.warning_amber_outlined,
      color: Colors.orange,
      titleKey: 'common.warning',
      showButton: true),

  /// Bilgi
  info(
      icon: Icons.info_outline,
      color: Colors.blue,
      titleKey: 'common.info',
      showButton: true),

  /// İşlem devam ediyor
  progress(
      icon: Icons.hourglass_empty,
      color: Colors.purple,
      titleKey: 'common.processing',
      showButton: false);

  const BildiriType(
      {required this.icon,
      required this.color,
      required this.titleKey,
      required this.showButton});

  /// İkon
  final IconData icon;

  /// Renk
  final Color color;

  /// Lokalizasyon anahtarı
  final String titleKey;

  /// Buton gösterilsin mi
  final bool showButton;

  String get localizedTitle => titleKey.tr();
}

/// Bildirim gösterir
Future<void> bildiri(BuildContext context, String message,
    {BildiriType type = BildiriType.success, String? title}) async {
  await showDialog(
    context: context,
    barrierDismissible: type != BildiriType.progress,
    builder: (context) => WillPopScope(
      onWillPop: () async => type != BildiriType.progress,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (type == BildiriType.progress)
                const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator())
              else
                Icon(type.icon, color: type.color, size: 48),
              const SizedBox(height: 16),
              Text(title ?? type.localizedTitle,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16)),
              if (type.showButton) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: type.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('common.ok'.tr(),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// Onay bildirimi gösterir
Future<bool> bildiriCevap(BuildContext context, String title,
    {required String des,
    String? yes,
    String? no,
    Color? yesColor,
    Color? noColor}) async {
  bool response = false;
  await showDialog(
    context: context,
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(des),
        actions: [
          TextButton(
              child: Text(no ?? 'common.no'.tr(),
                  style: const TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop()),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: yesColor ?? Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Text(yes ?? 'common.yes'.tr()),
            onPressed: () {
              response = true;
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    ),
  );

  return response;
}

/// Metin giriş bildirimi gösterir
Future<String?> bildiriGetText(BuildContext context, String title,
    {required String des,
    String? yes,
    String? no,
    Color? yesColor,
    Color? noColor}) async {
  bool response = false;
  String text = '';
  await showDialog(
    context: context,
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
            decoration: InputDecoration(label: Text(des)),
            keyboardType: TextInputType.phone,
            onChanged: (s) => text = s),
        actions: [
          TextButton(
            child: Text(no ?? 'common.cancel'.tr(),
                style: const TextStyle(color: Colors.grey)),
            onPressed: () {
              Navigator.of(context).pop();
              response = true;
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: yesColor ?? Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Text(yes ?? 'common.ok'.tr()),
            onPressed: () {
              response = true;
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    ),
  );

  return response ? text : null;
}

/// Soru bildirimi gösterir
Future<bool?> bildiriSoru(
    BuildContext context, String mes, String? yes, String? no) async {
  return await showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      content: Text(mes,
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: Text(no ?? 'common.no'.tr()),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: Text(yes ?? 'common.yes'.tr()),
        ),
      ],
    ),
    barrierDismissible: true,
  );
}
