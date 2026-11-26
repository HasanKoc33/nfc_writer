import 'package:easy_localization/easy_localization.dart';
import 'package:firesoft_base/firesoft_base.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/theme_manager.dart';
import '../../../data/services/in_app_purchase/in_app_purchase_helper.dart';
import '../pro_versiyon/pro_versiyon.dart';

/// Eski yan menünün (drawer) yerini alan ayarlar ekranı.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Diller kendi dillerindeki adlarıyla gösterilir; kullanıcı yanlışlıkla
  /// anlamadığı bir dile geçse bile kendi dilini bulabilir.
  static const List<(Locale, String, String)> _languages = [
    (Locale('en', 'US'), '🇺🇸', 'English'),
    (Locale('tr', 'TR'), '🇹🇷', 'Türkçe'),
    (Locale('de', 'DE'), '🇩🇪', 'Deutsch'),
    (Locale('fr', 'FR'), '🇫🇷', 'Français'),
    (Locale('es', 'ES'), '🇪🇸', 'Español'),
    (Locale('it', 'IT'), '🇮🇹', 'Italiano'),
    (Locale('ru', 'RU'), '🇷🇺', 'Русский'),
    (Locale('el', 'GR'), '🇬🇷', 'Ελληνικά'),
    (Locale('ar', 'SA'), '🇸🇦', 'العربية'),
    (Locale('ja', 'JP'), '🇯🇵', '日本語'),
    (Locale('ko', 'KR'), '🇰🇷', '한국어'),
    (Locale('zh', 'TW'), '🇹🇼', '繁體中文'),
  ];

  String _currentLanguageName(BuildContext context) {
    for (final (locale, flag, name) in _languages) {
      if (locale == context.locale) return '$flag  $name';
    }
    return context.locale.toLanguageTag();
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [
              for (final (locale, flag, name) in _languages)
                ListTile(
                  leading: Text(flag, style: const TextStyle(fontSize: 22)),
                  title: Text(name),
                  trailing: locale == context.locale
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(sheetContext).colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    context.setLocale(locale);
                    Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'info@firesoftyazilim.com',
      queryParameters: {'subject': 'email.subject'.tr()},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final themeManager = context.watch<ThemeManager>();

    return Scaffold(
      appBar: AppBar(title: Text('ui.settings.title'.tr())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          FutureBuilder<bool>(
            future: InAppPurchaseHelper().getSubscription(),
            builder: (context, snapshot) {
              if (snapshot.data != false) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _ProBanner(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProVersiyonScreen(),
                    ),
                  ),
                ),
              );
            },
          ),
          _SectionLabel('ui.settings.appearance'.tr()),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_outlined),
                    label: Text('drawer.theme.light'.tr()),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_outlined),
                    label: Text('drawer.theme.dark'.tr()),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto_outlined),
                    label: Text('drawer.theme.system'.tr()),
                  ),
                ],
                selected: {themeManager.themeMode},
                onSelectionChanged: (selection) =>
                    context.read<ThemeManager>().setThemeMode(selection.first),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionLabel('ui.settings.language'.tr()),
          Card(
            child: ListTile(
              leading: const Icon(Icons.translate_rounded),
              title: Text(_currentLanguageName(context)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showLanguagePicker(context),
            ),
          ),
          const SizedBox(height: 24),
          _SectionLabel('ui.settings.support'.tr()),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.star_outline_rounded),
                  title: Text('drawer.rate_app'.tr()),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final inAppReview = InAppReview.instance;
                    if (await inAppReview.isAvailable()) {
                      inAppReview.requestReview();
                    }
                  },
                ),
                Divider(indent: 56, color: scheme.outlineVariant),
                ListTile(
                  leading: const Icon(Icons.mail_outline_rounded),
                  title: Text('drawer.support'.tr()),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _contactSupport,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          AppFooter(),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProBanner extends StatelessWidget {
  const _ProBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ui.settings.premium_title'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ui.settings.premium_subtitle'.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
