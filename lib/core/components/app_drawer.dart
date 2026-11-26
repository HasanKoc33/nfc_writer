import 'package:firesoft_base/firesoft_base.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ui/screens/history_screen/history_screen.dart';
import '../../ui/screens/pro_versiyon/pro_versiyon.dart';
import '../theme/theme_manager.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.nfc,
                        size: 50,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'app.title'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: Text('drawer.home'.tr()),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: Text('drawer.history'.tr()),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HistoryScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.workspace_premium),
                  title: Text('drawer.remove_ads'.tr()),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProVersiyonScreen()));
                  },
                ),
                const Divider(),
                // Dil Seçimi
                ExpansionTile(
                  leading: const Icon(Icons.language),
                  title: Text('drawer.language.title'.tr()),
                  children: [
                    RadioListTile<Locale>(
                      title: Row(
                        children: [
                          const Text('🇹🇷 '),
                          Text('drawer.language.turkish'.tr()),
                        ],
                      ),
                      value: const Locale('tr', 'TR'),
                      groupValue: context.locale,
                      onChanged: (Locale? locale) {
                        if (locale != null) {
                          context.setLocale(locale);
                        }
                      },
                    ),
                    RadioListTile<Locale>(
                      title: Row(
                        children: [
                          const Text('🇺🇸 '),
                          Text('drawer.language.english'.tr()),
                        ],
                      ),
                      value: const Locale('en', 'US'),
                      groupValue: context.locale,
                      onChanged: (Locale? locale) {
                        if (locale != null) {
                          context.setLocale(locale);
                        }
                      },
                    ),
                    RadioListTile<Locale>(
                      title: Row(
                        children: [
                          const Text('🇷🇺 '),
                          Text('drawer.language.russian'.tr()),
                        ],
                      ),
                      value: const Locale('ru', 'RU'),
                      groupValue: context.locale,
                      onChanged: (Locale? locale) {
                        if (locale != null) {
                          context.setLocale(locale);
                        }
                      },
                    ),
                    RadioListTile<Locale>(
                      title: Row(
                        children: [
                          const Text('🇰🇷 '),
                          Text('drawer.language.korean'.tr()),
                        ],
                      ),
                      value: const Locale('ko', 'KR'),
                      groupValue: context.locale,
                      onChanged: (Locale? locale) {
                        if (locale != null) {
                          context.setLocale(locale);
                        }
                      },
                    ),
                    RadioListTile<Locale>(
                      title: Row(
                        children: [
                          const Text('🇸🇦 '),
                          Text('drawer.language.arabic'.tr()),
                        ],
                      ),
                      value: const Locale('ar', 'SA'),
                      groupValue: context.locale,
                      onChanged: (Locale? locale) {
                        if (locale != null) {
                          context.setLocale(locale);
                        }
                      },
                    ),
                    RadioListTile<Locale>(
                      title: Row(
                        children: [
                          const Text('🇹🇼 '),
                          Text('drawer.language.chinese'.tr()),
                        ],
                      ),
                      value: const Locale('zh', 'TW'),
                      groupValue: context.locale,
                      onChanged: (Locale? locale) {
                        if (locale != null) {
                          context.setLocale(locale);
                        }
                      },
                    ),
                    RadioListTile<Locale>(
                      title: Row(
                        children: [
                          const Text('🇫🇷 '),
                          Text('drawer.language.french'.tr()),
                        ],
                      ),
                      value: const Locale('fr', 'FR'),
                      groupValue: context.locale,
                      onChanged: (Locale? locale) {
                        if (locale != null) {
                          context.setLocale(locale);
                        }
                      },
                    ),
                    RadioListTile<Locale>(
                      title: Row(
                        children: [
                          const Text('🇩🇪 '),
                          Text('drawer.language.german'.tr()),
                        ],
                      ),
                      value: const Locale('de', 'DE'),
                      groupValue: context.locale,
                      onChanged: (Locale? locale) {
                        if (locale != null) {
                          context.setLocale(locale);
                        }
                      },
                    ),
                    RadioListTile<Locale>(
                      title: Row(
                        children: [
                          const Text('🇬🇷 '),
                          Text('drawer.language.greek'.tr()),
                        ],
                      ),
                      value: const Locale('el', 'GR'),
                      groupValue: context.locale,
                      onChanged: (Locale? locale) {
                        if (locale != null) {
                          context.setLocale(locale);
                        }
                      },
                    ),
                    RadioListTile<Locale>(
                      title: Row(
                        children: [
                          const Text('🇮🇹 '),
                          Text('drawer.language.italian'.tr()),
                        ],
                      ),
                      value: const Locale('it', 'IT'),
                      groupValue: context.locale,
                      onChanged: (Locale? locale) {
                        if (locale != null) {
                          context.setLocale(locale);
                        }
                      },
                    ),
                    RadioListTile<Locale>(
                      title: Row(
                        children: [
                          const Text('🇯🇵 '),
                          Text('drawer.language.japanese'.tr()),
                        ],
                      ),
                      value: const Locale('ja', 'JP'),
                      groupValue: context.locale,
                      onChanged: (Locale? locale) {
                        if (locale != null) {
                          context.setLocale(locale);
                        }
                      },
                    ),
                    RadioListTile<Locale>(
                      title: Row(
                        children: [
                          const Text('🇪🇸 '),
                          Text('drawer.language.spanish'.tr()),
                        ],
                      ),
                      value: const Locale('es', 'ES'),
                      groupValue: context.locale,
                      onChanged: (Locale? locale) {
                        if (locale != null) {
                          context.setLocale(locale);
                        }
                      },
                    ),
                  ],
                ),
                // Tema Seçimi
                ExpansionTile(
                  leading: const Icon(Icons.palette),
                  title: Text('drawer.theme.title'.tr()),
                  children: [
                    RadioListTile<ThemeMode>(
                      title: Text('drawer.theme.light'.tr()),
                      value: ThemeMode.light,
                      groupValue: context.read<ThemeManager>().themeMode,
                      onChanged: (ThemeMode? mode) {
                        if (mode != null) {
                          context.read<ThemeManager>().setThemeMode(mode);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('drawer.theme.dark'.tr()),
                      value: ThemeMode.dark,
                      groupValue: context.read<ThemeManager>().themeMode,
                      onChanged: (ThemeMode? mode) {
                        if (mode != null) {
                          context.read<ThemeManager>().setThemeMode(mode);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('drawer.theme.system'.tr()),
                      value: ThemeMode.system,
                      groupValue: context.read<ThemeManager>().themeMode,
                      onChanged: (ThemeMode? mode) {
                        if (mode != null) {
                          context.read<ThemeManager>().setThemeMode(mode);
                        }
                      },
                    ),
                  ],
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.star),
                  title: Text('drawer.rate_app'.tr()),
                  onTap: () async {
                    final InAppReview inAppReview = InAppReview.instance;
                    if (await inAppReview.isAvailable()) {
                      inAppReview.requestReview();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.support),
                  title: Text('drawer.support'.tr()),
                  onTap: () async {
                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: 'info@firesoftyazilim.com',
                      queryParameters: {
                        'subject': 'email.subject'.tr(),
                      },
                    );
                    if (await canLaunchUrl(emailLaunchUri)) {
                      await launchUrl(emailLaunchUri);
                    }
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          AppFooter(),
        ],
      ),
    );
  }
}
