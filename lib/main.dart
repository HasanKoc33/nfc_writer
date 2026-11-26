import 'package:easy_localization/easy_localization.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app/app.dart';
import 'core/app/app_init.dart';
import 'core/theme/theme_manager.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/analytics_service.dart';
import 'data/repositories/user_activity_repository.dart';
import 'data/services/dynamic_link/dynamic_link_service.dart';
import 'firebase_options.dart';
import 'ui/screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await MobileAds.instance.initialize();
  await AppInit.instance.init();
  FacebookAppEvents().logEvent(name: "app_launch");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService().initialize();
  await FirebaseMessagingService().initialize();
  await UserActivityRepository().registerUserActivity();
  await AnalyticsService().logAppOpen();
  await DynamicLinkService.loadSecrets();

  final prefs = await SharedPreferences.getInstance();
  final themeManager = ThemeManager(prefs);

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('tr', 'TR'),
        Locale('ru', 'RU'),
        Locale('ko', 'KR'),
        Locale('ar', 'SA'),
        Locale('zh', 'TW'),
        Locale('fr', 'FR'),
        Locale('de', 'DE'),
        Locale('el', 'GR'),
        Locale('it', 'IT'),
        Locale('ja', 'JP'),
        Locale('es', 'ES'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      // Bir dilde eksik anahtar varsa ham anahtar yerine İngilizcesi gösterilir.
      useFallbackTranslations: true,
      child: ChangeNotifierProvider(
        create: (_) => themeManager,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();

    return MaterialApp(
      title: 'NFC Writer',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [AnalyticsService().observer],
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeManager.getLightTheme(),
      darkTheme: ThemeManager.getDarkTheme(),
      themeMode: themeManager.themeMode == ThemeMode.system
          ? ThemeMode.system
          : themeManager.themeMode == ThemeMode.dark
              ? ThemeMode.dark
              : ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}
